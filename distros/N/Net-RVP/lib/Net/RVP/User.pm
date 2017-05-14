=head1 NAME

Net::RVP::User - RVP user encapsulation

=head1 SYNOPSIS

 my $user = $rvp->user('Fred_Smith');
 $user->watch() or die 'no such user';
 print "Email for ".($user->display())." is ".$user->email()."\n";

=head1 METHODS

=cut
package Net::RVP::User;

use strict;


=head2 new ( RVP object, URL )

Create new user object.

=cut
sub new {
  my ($class,$rvp,$url) = @_;
  die unless $url =~ /\/(\w+)$/;
  my $self = bless { rvp => $rvp, url => $url, user => $1, prop => {} },
   ref $class || $class;
  return $self;
}


=head2 name

Return the short name e.g. jsmith, bob_jones.

=cut
sub name {
  shift->{user}
}


=head2 url

Return the URL representing the user.

=cut
sub url {
  shift->{url}
}


=head2 display

Return the display name for the user.

=cut
sub display {
  shift->get('d:displayname');
}


=head2 email

Return the user email address.

=cut
sub email {
  shift->get('r:email');
}


=head2 state

Return user state (without the namespace prefix) e.g. 'idle', 'online',
'offline', etc.

=cut
sub state {
  # OK to use cache, we get propchange notifications on changes
  my $state = shift->get('r:state');
  $state =~ s/^r://;
  $state
}


# helper for get_all and watch; parse out properties into hash and store/return
# pass in the data tree and an optional arrayref for _findTree
sub _parse_prop {
  my ($self,$data,$where) = @_;

  # if we weren't given a search path, use default for properties
  $where ||= [qw(d:multistatus? d:response d:propstat d:prop)];

  # parse the returned XML
  $data = $self->{rvp}->_findTree($data,@$where);

  # set keys
  my %ret;
  while(my ($k,$v) = each %{$data}) {
    if(ref $v eq 'HASH') {
      my @keys = keys %$v;
      $v = @keys ? $keys[0] : '' if @keys < 2;
    }
    $ret{$k} = $v;
  }

  return \%ret;
}


=head2 change_event

Send XML tree for NOTIFY property change event (under r:notification).

=cut
sub change_event {
  my ($self,$data) = @_;
  my @ret = $self->_parse_prop($data,[qw(d:propertyupdate d:set d:prop)]);
  return $self->{rvp}->{sink}->change_event($self,@ret);
}


=head2 get_all

Read all available properties for the user.

Returns hashref on success, false on failure.  Some possible keys are: user
(this object), href (the canonical URL), and properties: d:displayname,
r:mobile-state, r:mobile-description, r:email, r:state (note that we normalize
the XML so the namespaces will stay the same).

=cut
sub get_all {
  my $self = shift;

  my $req = $self->{rvp}->_request(PROPFIND => "/instmsg/aliases/$self->{user}",
   depth => 0, XML => <<XML);
<d:propfind xmlns:d="DAV:" xmlns:r="http://schemas.microsoft.com/rvp/">
  <d:allprop/>
</d:propfind>
XML

  my ($res,$data) = $self->{rvp}->_sendXML($req);
  return 0 unless $data;

  return $self->{prop} = $self->_parse_prop($data);
}


=head2 watch

Subscribe to notifications for this user; renew if already subscribed.

Returns subscription timeout if successful, false otherwise.

=cut
sub watch {
  my $self = shift;
  
  my $req = $self->{rvp}->_request(SUBSCRIBE =>
   "/instmsg/aliases/$self->{user}",
   subscription_lifetime => $self->{rvp}->{renew});

  # first time or renewal?
  if($self->{watch}) {
    $req->header(subscription_id => $self->{watch}->{id});
  } else {
    $req->header(notification_type => 'update/propchange',
     call_back => $self->{rvp}->{url});
  }

  my ($res,$data) = $self->{rvp}->_sendXML($req);
  return 0 unless $res->is_success();
  return $self->{rvp}->{renew} if not $data;  # re-subscribe gets no XML

  # we get sent all properties, like a get_all, so set them
  $self->{prop} = $self->_parse_prop($data);

  # store the subscription id
  $self->{watch} = { principal => $req->uri(),
                     id => $res->header('subscription_id') };
  $self->{rvp}->{subs}->{$self->{watch}->{id}} = $self->{watch};

  return $self->{rvp}->{renew};
}


=head2 unwatch

Stop watching (unsubscribe).

Note that we don't unsubscribe on object destruction (because global
destruction order may be wrong), but we do when the RVP object is destroyed.

=cut
sub unwatch {
  my $self = shift;
  return unless $self->{watch};
  $self->{rvp}->unsubscribe($self->{watch});
}


=head2 get ( property [, no cache flag ] )

User name should be the URL name final part e.g. 'jsmith'.
If the 'no cache' flag is set, DON'T use the cache (default: use cache).

Properties may be 'd:' (DAV) or 'r:' (RVP) or 'a:' (ACL), e.g. 'd:displayname'.

Returns value, undef on failure.

=cut
sub get {
  my ($self,$prop,$no_cache) = @_;

  # use cache, user properties shouldn't change much
  if(not $no_cache and exists $self->{prop}->{$prop}) {
    return $self->{prop}->{$prop};
  }

  my $req = $self->{rvp}->_request(PROPFIND => "/instmsg/aliases/$self->{user}",
   depth => 0, XML => <<XML);
<d:propfind xmlns:d="DAV:" xmlns:r="http://schemas.microsoft.com/rvp/">
  <d:prop><$prop/></d:prop>
</d:propfind>
XML
# <d:multistatus xmlns:d='DAV:' xmlns:r='http://schemas.microsoft.com/rvp/' xmlns:a='http://schemas.microsoft.com/rvp/acl/'><d:response><d:href>http://laxhhim1.hq.ad.hilton.com/instmsg/aliases/peter_conrey</d:href><d:propstat><d:prop><d:displayname>Peter Conrey</d:displayname></d:prop><d:status>HTTP/1.1 200 Successful</d:status></d:propstat></d:response></d:multistatus>

  my ($res,$data) = $self->{rvp}->_sendXML($req);
  return 0 unless $data;
  my $value = $self->_parse_prop($data);
  $self->{prop}->{$prop} = $value->{$prop};
  return $self->{prop}->{$prop};
}


=head2 set( prop, value )

Set property.  Returns true on success, false on failure.

This should only be done on our own node, it should fail with an access error
on others.

=cut
sub set {
  my ($self,$prop,$value) = @_;

  my $req = $self->{rvp}->_request(PROPPATCH => $self->{url}, XML => <<XML);
<d:propertyupdate xmlns:d="DAV:" xmlns:r="http://schemas.microsoft.com/rvp/">
  <d:set><d:prop><$prop><r:leased-value>
    <r:value>$value</r:value>
  </r:leased-value></$prop></d:prop></d:set>
</d:propertyupdate> 
XML
  my $success = $self->{rvp}->_send($req)->is_success();
  $self->{prop}->{$prop} = $value if $success;
  return $success;
}


=head2 acl

Get ACL for user.

Returns true on success, false on failure (this method isn't needed so we don't
bother to parse out the XML yet, sorry).

Note that although it isn't shown in the Microsoft RVP "specification", ACLs
can also be set although this seems to be unnecessary for the most part
(although perhaps handy e.g. to disallow someone from receiving presence
information about onesself).

=cut
sub acl {
  my $self = shift;
  my $req = $self->_request(ACL => "/instmsg/aliases/$self->{user}");
  return $self->_send($req)->is_success();
}


=head2 activity

Sent when there's activity.  Updates the last activity time.

=cut
sub activity {
  my $self = shift;
  $self->{active} = time;
}


=head2 lag

Returns lag time since last activity, undef if no activity.

=cut
sub lag {
  my $self = shift;
  return $self->{active} && time-$self->{active};
}


=head1 AUTHOR

David Robins E<lt>dbrobins@davidrobins.netE<gt>.

=cut


1;
