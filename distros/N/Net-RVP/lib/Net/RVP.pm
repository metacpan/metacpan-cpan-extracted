=head1 NAME

Net::RVP - implementation of the Rendez-Vous Protocol for instant messaging

=head1 SYNOPSIS

 my $rvp = RVP->new(
  host  => '1.2.3.4:80',
  name  => 'First_Last',
  user  => 'domain\\username',
  pass  => 'password',
  site  => 'machine.domain.com');

 $rvp->login();

 # ...

=head1 METHODS

=cut
package Net::RVP;

use strict;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Status;
use URI;
use XML::Simple;
use Digest::MD5 qw(md5_hex);
use Time::HiRes qw(gettimeofday);

use Net::RVP::User;
use Net::RVP::Session;
use Net::RVP::Sink;

our $Debug = 0;


=head2 new ( named parameters )

Requires host (this machine, dotted-IP acceptable, for callbacks), name
('Joe_Smith'), user ('hq\jsmith'), password, and site for server (optional
':port' at end allowed).

Optional: agent - user-agent string; renew - renewal time for subscriptions;
sink - event sink object (see L<Net::RVP::Sink>).

=cut
sub new {
  my ($class,%param) = @_;
  die 'host, name, user, pass, and site required' if
   grep { not $param{$_} } qw(host name user pass site);
  my $self;
  @{$self}{qw(host name user pass site sink)} =
   delete @param{qw(host name user pass site sink)};
  bless $self, ref $class || $class;
  $Debug = delete $param{debug};
  $self->{port} = ($self->{site} =~ s/:(\d+)$//) ? $1 : 80;
  $self->{agent} = delete $param{agent};
  $self->{renew} = delete $param{renew} || 14400;

  $self->{parser} = XML::Simple->new(ContentKey => '', ForceArray => 0,
   ForceContent => 0, KeepRoot => 1);

  die "unknown parameter(s): ".(join ', ', keys %param) if keys %param;

  $_ = lc $_ for(@{$self}{qw(name site)});

  $self->{sink} ||= Net::RVP::Sink->new(); 
  $self->{sink}->RVP($self);

  return $self;
}


=head2 login

Try to log in, returns false on error, renewal time otherwise.

=cut
sub login {
  my ($self,$agent) = @_;
  $self->logout();  # if logged in

  $self->{ua} = LWP::UserAgent->new(keep_alive => 1);
  $self->{ua}->agent($self->{agent}) if $self->{agent};  # MS is msmsgs/4.6.0.84

  # cb is the callback, node is without the port i.e. for the request URL
  # NB: we get an access error if we include the port for a foreign SUBSCRIBE!
  # i.e. if it's not port 80 it probably won't work
  $self->{base} =
   "http://$self->{site}".($self->{port}==80 ? '' : ":$self->{port}");
  $self->{url} = "$self->{base}/instmsg/aliases/$self->{name}";

  $self->{ua}->credentials("$self->{site}:$self->{port}",'',
   $self->{user},$self->{pass});

  # link logical address to our server
  my $req = $self->_request(SUBSCRIBE => "/instmsg/aliases/$self->{name}",
   call_back => "http://$self->{host}", notification_type => 'pragma/notify',
   subscription_lifetime => $self->{renew});
  my $res = $self->_send($req);
  return 0 unless $res->is_success();

  # set login flag and start subscriptions, users, and conversations lists
  $self->{login} = $res->header('subscription-id');
  $self->{subs}  = {};  # don't count the above, we can't unsubscribe it anyway
  $self->{users} = {};  # keyed by user URL
  $self->{sesss} = {};  # keyed by Session-Id

  # create our own user object to get our properties
  my $me = $self->user($self->{name});
  $me->watch();

  # clear out old subscriptions
  my $id = $res->header('subscription_id');
  my @id = grep { $_->{id} != $id } $self->_subscriptions($self->{name});
  $self->_unsubscribe($_) for @id;

  return $res->header('subscription_lifetime');
}


=head2 renew

Renew login subscription.  Returns new renewal time, false on error.

=cut
sub renew {
  my $self = shift;
  die 'not logged in' unless $self->{login};

  my $req = $self->_request(SUBSCRIBE => "/instmsg/aliases/$self->{name}",
   subscription_id => $self->{login}, subscription_lifetime => $self->{renew});
  my $res = $self->_send($req);
  return $res->is_success() ? $self->{renew} : 0;
}


=head2 logout

Log out.

=cut
sub logout {
  my $self = shift;
  return unless $self->{login};

  # unsubscribe to everything (except the first, which returns not implemented)
  $self->_unsubscribe($self->{subs}->{$_}) for keys %{$self->{subs}};
  $self->{subs} = {};
  $self->{login} = 0;
}


=head2 base

Return the base address of the server e.g. http://foo.bar:port

=cut
sub base {
  shift->{base}
}


=head2 url

Return local node (must be logged in) as http URL.

=cut
sub url {
  shift->{url}
}


=head2 name

Return user name (short form, e.g. jsmith or bob_jones).

=cut
sub name {
  shift->{name}
}


=head2 server

Return name of the remote server we're hitting, with no 'http' etc. in front.

=cut
sub server {
  shift->{site}
}


=head2 host

Return local callback: (address, port) in list context, proto://address:port in
scalar context.

=cut
sub host {
  my $self = shift;
  if(wantarray) {
    return ($1,$2) if $self->{host} =~ /^([^:]+):(\d+)$/;
    return ($self->{host},80);
  }
  return "http://$self->{host}";
}


=head2 self

Return our own user object.

=cut
sub self {
  my $self = shift;
  return $self->{users}->{$self->{url}};
}


=head2 user ( name | URL )

Create and return a user object.  Doesn't necessarily imply that the user
exists.  Name should be the short name on the server ('jsmith'), or a URL.

=cut
sub user {
  my ($self,$url) = @_;
  $url = "$self->{base}/instmsg/aliases/$url" unless $url =~ /^(\w+):/;
  $url = lc $url;
  if(my $obj = $self->{users}->{$url}) {
    return $obj;
  }
  return $self->{users}->{$url} = Net::RVP::User->new($self,$url);
}


=head2 session

Create and return a session (conversation) object (see L<Net::RVP::Session>).

=cut
sub session {
  my $self = shift;

  # create a session-id (GUID); use MD5, insert hyphens, convert to uppercase
  # we want {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx} (8,4,4,12) where x = %X
  # md5_hex emits data like '098f6bcd4621d373cade4e832627b4f6'
  for(my $tries = 10; $tries >= 0; $tries--) {
    my $guid = uc md5_hex("$self->{host}:$self->{user}:".(scalar gettimeofday).
     rand);
    $guid =~ s/^(\w{8})(\w{4})(\w{4})(\w{4})(\w{12})$/{$1-$2-$3-$4-$5}/;
    return $self->{sesss}->{$guid} = Net::RVP::Session->new($self,$guid)
     unless $self->{sesss}->{$guid};
    die "can't create unique GUID!" unless $tries;
  }
}


# internal sub: pass method, URL (or just a path), and headers (name => value)
# returns an HTTP::Request object; adds default required headers
# special 'XML' header means set content and content-type; adds XML version
sub _request {
  my ($self,$type,$url,%param) = @_;

  $url = $self->{url} unless $url;
  unless($url =~ /^\w+:/) {
    $url =~ s!^/!!;
    $url = "http://$self->{site}/$url";
  }

  my $req = HTTP::Request->new($type => $url);

  if(my $content = delete $param{XML}) {
    $content = "<?xml version=\"1.0\"?>\n$content";
    $req->content($content);  # content-length set in _sendXML
    $param{content_type} = 'text/xml';
  }

  $param{host}                      ||= $self->{site};  # w/o the port
  $param{RVP_notifications_version} ||= 0.2;
  $param{RVP_from_principal}        ||= $self->{url};

  $req->header(%param);
  return $req;
}
  

# pass true parameter to get the response back else just true/success false/fail
# returns: result object
sub _send {
  my ($self,$req) = @_;

  # set content-length header if needed
  my $content = $req->content_ref();
  $req->header(content_length => length $$content) if length $$content;

  $Debug->("sent:\n".$req->as_string()."\n---\n") if $Debug;
  my $res = $self->{ua}->request($req);
  $Debug->("got:\n".$res->as_string()."\n---\n") if $Debug;
  return $res;
}


# normalize schemas using the passed-in map (helper for _sendXML)
# we return rather than changing in place because we need to change keys...
sub _normalize {
  my ($map,$tree) = @_;
  my %new;
  while(my ($k,$v) = each %{$tree}) {
    if($k =~ /^(\w+):/ and $map->{$1}) {
      my $prefix = $1;
      $k =~ s/^$prefix/$map->{$prefix}/;
    }
    $v = [$v] unless ref $v eq 'ARRAY';
    for(@{$v}) {
      $_ = _normalize($map,$_) if ref eq 'HASH';
    }
    $new{$k} = @{$v} > 1 ? $v : $v->[0];
  }
  \%new
}


# wrap send: return (response object, parsed XML) on success, (response object)
# on failure
sub _sendXML {
  die unless wantarray;
  my ($self,$req) = @_;
  my $res = $self->_send($req);
  return ($res) unless $res->is_success();

  my $tree;
  $tree = $self->_parseXML($res->content())
   if $res->header('content_type') =~ /^text\/xml\b/i;
  return ($res,$tree);
}


# internal method to parse and normalize XML
my %canon = ('DAV:' => 'd',
             'http://schemas.microsoft.com/rvp/' => 'r',
             'http://schemas.microsoft.com/rvp/acl/' => 'a',
);
sub _parseXML {
  my ($self,$data) = @_;
  my $tree = eval { $self->{parser}->XMLin($data); };  # dies on error
  if($@) {
    print STDERR "parse failed: $data\n";
    die $@;
  }

  # normalize the XML schemas: d=DAV, r=RVP, a=RVL ACL
  # we need the top level form XMLin for the xmlns declarations, but we can go
  # ahead and strip it off for our clients
  my %map;
  my @keys = keys %{$tree};
  my $top = $tree->{$keys[0]};
  $top = $top->[0] if ref $top eq 'ARRAY';
  if(ref $top eq 'HASH') {
    while(my ($k,$v) = each %{$top}) {
      if($k =~ /^xmlns:(\w+)$/) {
        $map{$1} = $canon{$v} if exists $canon{$v};
      }
    }
  }
  return _normalize(\%map,$tree);
}


# helper to look through XML for a 'path'
#
# pass in an XML::Simple-type hash representing an XML document,
# and a list of element names, which should be contained within each other
# e.g. qw(foo bar baz) => <foo><bar><baz>[returns this]</baz></bar></foo>
# the last element may be '1' to force returning an arrayref
# append '?' to a (non-final) element to make it optional (i.e. skip if absent)
sub _findTree {
  my ($self,$top) = splice @_,0,2;
  my $path = '';
  push @_,'0' unless $#_ >= 0 and $_[-1] eq '1';
  while(defined(my $elem = shift)) {
    my $optional = $elem =~ s/\?$//;
    my $multi = ref $top eq 'ARRAY';
    return $multi ? $top : [$top] if $elem eq '1';

    if($multi) {
      die "too many elements at $path" unless $#$top < 1;
      $top = $top->[0];
    }
    return $top if $elem eq '0';
    $path .= "/$elem";  # (add to error path even if optional)

    if(exists $top->{$elem}) {
      $top = $top->{$elem};
    } elsif(not $optional) {
      die "can't find $path";
    }
  }
}


# helper to look through XML for a text string
sub _findText {
  my $self = shift;
  my $ret = $self->_findTree(@_);
  $ret = $ret->{''} if ref $ret eq 'HASH' and exists $ret->{''};
  die "expected text, got reference [@_]" if ref $ret;
  return $ret;
}


# helper to look through XML for a list
sub _findArray {
  my $self = shift;
  return $self->_findTree(@_,1);
}


=head2 status ( value )

Set online status ('online', 'offline', others...).

=cut
sub status {
  my ($self,$value) = @_;
  my $req = $self->_request(PROPPATCH => 0, XML => <<XML);
<d:propertyupdate xmlns:d="DAV:" xmlns:r="http://schemas.microsoft.com/rvp/">
  <d:set><d:prop><r:state><r:leased-value>
    <r:value><r:$value/></r:value>
    <r:default-value><r:offline/></r:default-value> 
    <r:timeout>$self->{renew}</r:timeout>
  </r:leased-value></r:state></d:prop></d:set>
</d:propertyupdate> 
XML
  return $self->_send($req)->is_success();
}


# _type ( type )
#
# Return canonical type given index, leaves alone if not an in-range number.
#
my @Type = qw(pragma/notify update/propchange);
sub _type {
  my $type = shift;
  $type ||= 0;
  $type = $Type[$type] if $type =~ /^\d+$/ and $type <= $#Type;
  $type
}


# _subscriptions
#
# Stores a list of (user uri,id,principal,href,timeout) hashrefs.  The URI
# and the principal will probably be the same (and match the user).
#
sub _subscriptions {
  die unless wantarray;
  my ($self,$user,$type) = @_;
  $type = _type($type);
  my $req = $self->_request(SUBSCRIPTIONS => "/instmsg/aliases/$user",
   notification_type => $type);

  my ($res,$data) = $self->_sendXML($req);
  return 0 unless $data;

  # get our URI
  my $uri = $req->uri();
  $uri = $uri->as_string() if ref $uri;

  # walk returned subscriptions
  my $subs = $self->_findArray($data,qw(r:subscriptions? r:subscription));

  my @ret;
  for my $sub(@{$subs}) {
    my $pr = $data->{'a:principal'};
    $pr = $pr->{'a:rvp-principal'} if ref $pr;
    push @ret, { uri => $uri, principal => $pr, href => $sub->{'d:href'},
     id => $sub->{'r:subscription-id'}, timeout => $sub->{'d:timeout'} };
  }
  
  @ret;
}


# _unsubscribe ( item from subscriptions() call )
#
# Returns true on success.
#
sub _unsubscribe {
  my ($self,$item) = @_;
  my ($href,$id) = @{$item}{qw(principal id)};
  my $req = $self->_request(UNSUBSCRIBE => $href, subscription_id => $id);
  return $self->_send($req)->is_success();
}


=head2 notify ( HTTP::Request object )

Pass in an HTTP request parsed from the notify server (how you obtain and parse
incoming requests is beyond the scope of this module).  It will make callbacks
to methods in this object which may be overloaded as desired.

Returns an HTTP::Response object.

=cut
sub notify {
  my ($self,$req) = @_;
  my ($uri,$top) = $req->uri();
  $uri = URI->new($uri) unless ref $uri;

  # notification to our node
  if($req->method() eq 'NOTIFY' and $uri->path() eq '/') {
    $top = $self->_findTree($self->_parseXML($req->content()),'r:notification');
    
    while(my($top_k,$top_v) = each %$top) {

      # conversation
      if($top_k eq 'r:message') {

        # parse out source and destination
        my $src = $self->_findText($top_v,'r:notification-from','r:contact',
         'd:href');
        $src = $self->user($src);
        my $dst = $self->_findText($top_v,'r:notification-to','r:contact',
         'd:href');
        $dst = $self->user($dst);
        my $msg = $self->_findText($top_v,'r:msgbody','r:mime-data');

        # parse the message
        my @part = split /\x0d?\x0a\x0d?\x0a/, $msg, 2;
        $part[0] =~ s/\x0d?\x0a\s+/ /g;
        my @header = split /\x0d?\x0a/, $part[0];
        my %header = map { /^([^:]+):\s*(.*)$/; (lc $1 => $2) } @header;
        return 'message missing session-id'
         unless my $sid = uc $header{'session-id'};
        my $sess = $self->{sesss}->{$sid};
        return 'message missing content-type'
         unless my $type = lc $header{'content-type'};
        $type =~ s/;.*$//;

        # we might be coming in mid-session; be robust, create a new one
        my $res;
        unless($sess) {
          $sess = $self->{sesss}->{$sid} = Net::RVP::Session->new($self,$sid);
          $self->{sink}->open_event($sess);
        }
        unless($sess->has($src)) {
          $sess->join_event($src);
          $res = $self->{sink}->join_event($src,$sess);
        }

        # control message: open conversation or typing message
        if($type eq 'text/x-msmsgscontrol') {
          if($header{'typinguser'}) {
            $sess->typing_event($src);
            my $ret = $self->{sink}->typing_event($src,$sess);
            $src->activity();
            return $ret;
          } else {
            $src->activity();
            return $res || HTTP::Response->new(RC_OK,'User Already Present');
          }

        # part message
        } elsif($type eq 'text/x-imleave') {
          $sess->part_event($src);
          my $ret = $self->{sink}->part_event($src,$sess);
          $src->activity();
          return $ret;

        # actual message, should be text/plain but we take anything
        } else {
          $sess->message_event($src,$part[1]);
          my $ret = $self->{sink}->message_event($src,$sess,$part[1]);
          $src->activity();
          return $ret;
        }

      # property change
      } elsif($top_k eq 'r:propnotification') {

        # parse out source
        my $src = $self->_findText($top_v,'r:notification-from','r:contact',
         'd:href');
        $src = $self->user($src);

        return $src->change_event($top_v);

      # unknown key, return error
      } elsif($top_k !~ /^xmlns:/) {
        return "unknown top-level key for NOTIFY: '$top_k'";
      }
    }
  }

  return 'unknown request';
}


# DESTROY
#
# Destructor.
#
sub DESTROY {
  my $self = shift;
  $self->logout();
}


=head1 AUTHOR

David Robins E<lt>dbrobins@davidrobins.netE<gt>.

=head1 SEE ALSO

L<Net::RVP::User>, L<LWP::UserAgent>, L<HTTP::Parser> for parsing HTTP requests.

=cut


1;
