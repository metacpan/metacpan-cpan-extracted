# Net::RGTP                    -*- cperl -*-
#
# This program is free software; you may distribute it under the same
# conditions as Perl itself.
#
# Copyright (c) 2005 Thomas Thurman <marnanel@marnanel.org>

################################################################

package Net::RGTP;

use strict;
use warnings;
use vars qw(@ISA $VERSION);

use Socket 1.3;
use IO::Socket;
use Net::Cmd;
use Digest::MD5 qw(md5_hex);

$VERSION = '0.10';
@ISA     = qw(Exporter Net::Cmd IO::Socket::INET);

use constant GROGGS => 'rgtp-serv.groggs.group.cam.ac.uk';
use constant RGTP => 'rgtp(1431)';

################################################################

sub new
{
  my $package  = shift;
  my %args  = @_;

  my $self = $package->SUPER::new(PeerAddr => $args{Host} || GROGGS, 
				  PeerPort => $args{Port} || RGTP,
				  LocalAddr => $args{'LocalAddr'},
				  Proto    => 'tcp',
				  Timeout  => defined $args{Timeout}?
				                  $args{Timeout}: 120
				 ) or return undef;

  $self->debug(100) if $args{'Debug'};

  unless ($self->response) {
    $@ = "Couldn't get a response from the server";
    return undef;
  }

  ${*$self}{'net_rgtp_groggsbug'} = $self->message =~ /GROGGS system/;
  
  if ($self->code()<230 || $self->code()>232) {
    $@ = "Not an RGTP server";
    return undef;
  }

  $self->_set_alvl;

  $self;
}

sub access_level {
  my $self = shift;

  return ${*$self}{'net_rgtp_status'};
}

sub latest_seq {
  my $self = shift;

  return ${*$self}{'net_rgtp_latest'};
}

sub motd {
  my $self = shift;

  $self->command('MOTD');
  $self->_read_item(no_parse_headers=>1,
		    motd=>1);
}

sub item {
  my ($self, $itemid) = @_;

  return $self->motd if $itemid eq 'motd';

  return undef unless _is_valid_itemid($itemid);

  $self->command('ITEM', $itemid);
  $self->_read_item;
}

sub quick_item {
  my ($self, $itemid) = @_;

  return $self->motd if $itemid eq 'motd';

  my %result = ();

  $self->command('STAT', $itemid);
  $self->response;

  my ($parent, $child, $edit, $reply, $subject) =
    $self->message =~ /^([A-Za-z]\d{7}|\s{8}) ([A-Za-z]\d{7}|\s{8}) ([0-9a-fA-F]{8}|\s{8}) ([0-9a-fA-F]{8}) (.*)$/;

  $result{'parent' } = $parent    if $parent ne '        ';
  $result{'child'  } = $child     if $child  ne '        ';
  $result{'edit'   } = hex($edit) if $edit   ne '        ';
  $result{'reply'  } = hex($reply);
  $result{'subject'} = $subject;

  \%result;
}

sub login {
  my ($self, $userid, $secret) = @_;

  $userid ||= 'guest';

  $self->command('USER', $userid);
  $self->response;

  # Did they let us in for just saying who we were?
  if ($self->code >= 230 && $self->code <= 233) {
    if (defined $secret) {
      $@ = 'Unexpected lack of security-- possible man in the middle attack?';
      return undef;
    }

    return $self->_set_alvl;
  }

  if ($self->code eq '500') {
    $@ = 'Already logged in';
    return undef;
  }
  $self->_expect_code('130');

  my ($algorithm) = $self->message =~ /^(.*?) /;
  if ($algorithm eq 'MD5') {
    $@ = "Unknown algorithm: $algorithm";
  }

  $self->response;
  $self->_expect_code('333');
  my ($server_nonce) = $self->message =~ /([a-zA-Z0-9]{32})/;
  $server_nonce = pack("H*", $server_nonce);

  $secret = pack("H*", $secret);

  my $flipped_secret = '';
  for (my $i=0; $i<length($secret); $i++) {
    $flipped_secret .= chr((~ord(substr($secret,$i,1)) & 0xFF));
  }

  my $munged_userid = substr($userid, 0, 16);
  while (length($munged_userid)<16) {
    $munged_userid .= chr(0);
  }

  my $client_nonce = '';
  for (my $i=0; $i<16; $i++) {
    $client_nonce .= chr(int(rand(256)));
  }

  my $client_hash = md5_hex($client_nonce,
			    $server_nonce,
			    $munged_userid,
			    $flipped_secret);
  
  my $server_hash = md5_hex($server_nonce,
			    $client_nonce,
			    $munged_userid,
			    $secret);
  
  # Now we prove to the server that we know the secret...
  
  $self->command('AUTH', $client_hash, unpack('H*',$client_nonce));

  # ...and it proves the same to us.

  $self->response;
    
  unless ($server_hash eq substr(lc($self->message), 0, 32)) {
    $@ = "server failed to authenticate to us";
    return undef;
  }

  $self->response;

  return $self->_set_alvl;
}

sub items {
  my $self = shift;
  my $latest_seq = ${*$self}{'net_rgtp_latest'} || 0;

  if (defined ${*$self}{'net_rgtp_latest'}) {
    $self->command('INDX', sprintf('#%08x', ${*$self}{'net_rgtp_latest'}+1));
  } else {
    $self->command('INDX');
    ${*$self}{'net_rgtp_index'} = {};
  }

  $self->response;

  if ($self->code eq '531') {
    $@ = 'No reading access';
    return undef;
  }
  $self->_expect_code('250');

  for my $line (@{$self->read_until_dot}) {
    my $seq = hex(substr($line, 0, 8));
    my $timestamp = hex(substr($line, 9, 8));
    my $itemid = substr($line, 18, 8);
    my $from = substr($line, 27, 75);
    my $type = substr($line, 103, 1);
    my $subject = substr($line, 105);
      
    $from =~ s/\s*$//;
    $subject =~ s/\s*$//;

    if ($type eq 'M') {
      $itemid = 'motd';
      $subject = 'Message of the Day';
      $type = 'I';
    }

    if ($type eq 'C') {
      ${*$self}{'net_rgtp_childlink'} = $itemid;
    } elsif ($type eq 'F') {
      if (defined ${*$self}{'net_rgtp_childlink'}) {
	${*$self}{'net_rgtp_index'}
	  { ${*$self}{'net_rgtp_childlink'} }{'child'} = $itemid;
	${*$self}{'net_rgtp_index'}
	  { $itemid }{'parent'} = ${*$self}{'net_rgtp_childlink'};
	delete ${*$self}{'net_rgtp_childlink'};
      }
    }
    
    if ($type eq 'R' or $type eq 'I' or $type eq 'C') {
      ${*$self}{'net_rgtp_index'}{ $itemid }{'subject'} = $subject;
      ${*$self}{'net_rgtp_index'}{ $itemid }{'posts'}++;
      ${*$self}{'net_rgtp_index'}{ $itemid }{'timestamp'} = $timestamp;
      ${*$self}{'net_rgtp_index'}{ $itemid }{'seq'} = $seq;
    }

    $latest_seq = $seq if $seq > $latest_seq;
	
  }

  ${*$self}{'net_rgtp_latest'} = $latest_seq;

  ${*$self}{'net_rgtp_index'};

}

sub state {
  my ($self, $setting) = @_;

  if (defined $setting) {
    if (defined $setting->{'latest'}) {
      ${*$self}{'net_rgtp_latest'} = $setting->{'latest'};
      ${*$self}{'net_rgtp_index'}  = $setting->{'index'};
    } else {
      delete ${*$self}{'net_rgtp_latest'};
      delete ${*$self}{'net_rgtp_index'};
    }
  } else {
    if (defined ${*$self}{'net_rgtp_latest'}) {
      return {
	      latest => ${*$self}{'net_rgtp_latest'},
	      index  => ${*$self}{'net_rgtp_index'},
	     };
    } else {
      return {
	      index  => {},
	     };
    }
  }
}

sub post {

  my ($self, $itemid, $text, %args) = @_;

  my $grogname = $args{'Grogname'} || ' ';
  my $seq;

  my $item_was_full = $self->item_is_full;

  delete ${*$self}{'net_rgtp_item_is_full'};
  delete ${*$self}{'net_rgtp_item_has_grown'};

  $self->command('DATA');
  $self->response;

  die "No posting access" if $self->code eq '531';
  $self->_expect_code('150');

  $text =~ s/\n\./\n\.\./g; # dot-doubling

  $self->datasend("$grogname\n");
  $self->datasend($text);
  $self->dataend;

  return undef if $self->_malformed_posting;
  $self->_expect_code('350');

  if ($itemid eq 'new' || $itemid eq 'continue') {

    my $subject = $args{'Subject'}
      or die "Need a subject line";

    if ($itemid eq 'continue') {
      die "We haven't reached the end of an item"
	unless $item_was_full;

      $self->command('CONT', $subject);
    } else {
      $self->command('NEWI', $subject);
    }

    $self->response;

    return undef if $self->_malformed_posting;

    if ($self->code eq '122') {
      $self->response;
      $self->_expect_code('422');

      ${*$self}{'net_rgtp_item_has_grown'} = 1;
      
      return undef;
    }

    if ($self->code eq '520') {
      $@ = 'We haven\'t reached the end of an item';
    }

    $self->_expect_code('120');

    $self->response;
    $self->_expect_code('220');
    ($itemid) = $self->message =~ /^([A-Za-z][0-9]{7})/;
    # seq is extracted below.

  } elsif ($itemid eq 'motd') {

    $@ = 'Not implemented';
    return undef;

  } else {

    return undef unless _is_valid_itemid($itemid);

    if (defined $args{'Seq'}) {
      my $quick = $self->quick_item($itemid);

      if ($quick->{'reply'} != $args{'Seq'}) {
	$@ = 'Item has apparently grown';
	${*$self}{'net_rgtp_item_has_grown'} = 1;
	return undef;
      }
    }

    $self->command('REPL', $itemid);
    $self->response;

    return undef if $self->_malformed_posting;

    if ($self->code eq '421') {
      # Item is full.

      ${*$self}{'net_rgtp_item_is_full'} = 1;
      $@ = 'Item is full';
      return undef;
    }

    if ($self->code eq '122') {
      $self->response;
      $self->_expect_code('422');

      ${*$self}{'net_rgtp_item_has_grown'} = 1;
      $@ = 'Item has gone into a continuation';
      return undef;
    }
	
    $self->_expect_code('220');

    # So, success!

  }

  ($seq) = $self->message =~ /([A-Fa-f0-9]{8})  /;

  if (wantarray) {
    return ($itemid, hex($seq));
  } else {
    return $itemid;
  }
}

sub item_is_full {
  my ($self) = @_;

  return defined ${*$self}{'net_rgtp_item_is_full'};
}

sub item_has_grown {
  my ($self) = @_;

  return defined ${*$self}{'net_rgtp_item_has_grown'};
}

################################################################
# INTERNAL ROUTINES

sub _read_item {
  my $self = shift;
  my %args = @_;
  my %result = ();
  my @responses = ();
  my $current_response = ();
  my ($seq, $timestamp);

  $self->response;
  die "No reading access" if $self->code eq '531';
  return undef            if $self->code eq '410';
  $self->_expect_code('250');

  my $status = $self->getline;

  if ($args{'motd'}) {	
    ($seq, $timestamp) =
      $status =~ /^([0-9a-fA-F]{8}|\s{8}) ([0-9a-fA-F]{8})/;
    
    if (${*$self}{'net_rgtp_groggsbug'}) {
      # They have it backwards!
      $result{'seq'} = hex($timestamp);
      $result{'timestamp'} = hex($seq);
    } else {
      $result{'seq'} = hex($seq);
      $result{'timestamp'} = hex($timestamp);
    }
  } else {
    my ($parent, $child, $edit, $reply) =
      $status =~ /^([A-Za-z]\d{7}|\s{8}) ([A-Za-z]\d{7}|\s{8}) ([0-9a-fA-F]{8}|\s{8}) ([0-9a-fA-F]{8})/;
    
    $result{'parent'} = $parent    if $parent ne '        ';
    $result{'child' } = $child     if $child  ne '        ';
    $result{'edit'  } = hex($edit) if $edit   ne '        ';
    $result{'reply' } = hex($reply);
  }

  for my $line (@{$self->read_until_dot}) {
    if (($seq, $timestamp) = $line =~ /^\^([0-9a-fA-F]{8}) ([0-9a-fA-F]{8})/) {
      push @responses, $current_response if $current_response;
      $current_response = { seq=>hex($seq), timestamp=>hex($timestamp) };
      
    } else {
      $line =~ s/^\^\^/\^/;
      $line =~ s/^\.\./\./;
      $current_response->{'text'} .= $line;
    }
  }

  $current_response->{'text'} =~ s/\n\n$/\n/;

  push @responses, $current_response;

  unless ($args{'no_parse_headers'}) {
    for my $response (@responses) {

      $response->{'text'} =~ s/\n\n$/\n/;

      my $username;
      if (($username) = $response->{'text'} =~ /^.* from (.*) at .*\n/) {
	
	if ($username =~ /\(.*\)$/) {
	  ($response->{'grogname'}, $response->{'poster'}) =
	    $username =~ /^(.*) \((.*)\)$/;
	} else {
	  $response->{'poster'} = $username;
	  if ($response->{'text'} =~ /From (.*)\n/) {
	    $response->{'grogname'} = $1;
	  }
	}
	
      }
	    
      if ($response->{'text'} =~ /Subject: (.*)\n/) {
	$result{'subject'} = $1;
      }
	    
      $response->{'text'} =~ s/^(.|\r|\n)*?\r?\n\r?\n//;
    }
  }

  $result{'posts'} = \@responses;

  if ($args{'motd'}) {	
    $result{'posts'}[0]->{'seq'} = delete $result{'seq'};
    $result{'posts'}[0]->{'timestamp'} = delete $result{'timestamp'};
  }

  \%result;
}

sub _is_valid_itemid {
  if (shift =~ /^[A-Za-z]\d{7}$/) {
    return 1;
  } else {
    $@ = 'Invalid itemid';
    return 0;
  }
}

sub _set_alvl {
  my $self = shift;

  die "Expected status response"
    if $self->code()<230 || $self->code()>233;

  ${*$self}{'net_rgtp_status'} = $self->code()-230;
}

sub _expect_code {
  my ($self, $expectation) = @_;

  if ($self->code ne $expectation) {
    die "Low-level protocol error: expected $expectation and got ".$self->code;
  }
}

sub _malformed_posting {

  my $self = shift;

  if ($self->code eq '423') { $@ = 'Malformed text';     return 1; }
  if ($self->code eq '424') { $@ = 'Malformed subject';  return 1; }
  if ($self->code eq '425') { $@ = 'Malformed grogname'; return 1; }

  return 0;
}

1;

__END__

=head1 NAME

Net::RGTP - Reverse Gossip client

=head1 SYNOPSIS

  use Net::RGTP;

  my $rgtp = Net::RGTP->new(Host=>'gossip.example.com')
    or die "Cannot connect to RGTP server!";

  $rgtp->login('spqr1@cam.ac.uk', 'DEADBEEFCAFEF00D');

  for my $itemid (keys %{$rgtp->items}) {
    my $item = $rgtp->item($itemid);

    print $itemid, ' ', $item->{'subject'}, ' has ',
      scalar(@{$item->{'posts'}}),
      " posts.\n";
  }

=head1 DESCRIPTION

C<Net::RGTP> is a class implementing the RGTP bulletin board protocol,
as used in the Cambridge University GROGGS system. At present it provides
read-only access only.

=head1 OVERVIEW

RGTP stands for Reverse Gossip Transfer Protocol. An RGTP board, such
as GROGGS, consists essentially of a set of "items", each denoted by
an eight-character itemid such as "A1240111". An item consists of a
sequence of posts on a given subject, identified by a subject string
attached to the item. When an item has reached a certain size,
attempting to post to it will instead generate a new item, known as
a "continuation" or "child" item, with a new itemid and subject string.
RGTP keeps track of which items are children of which parent items,
thus allowing long chains of discussion to be built.

The first character of itemids was "A" in 1986, the first year of
GROGGS's existence, and has been incremented through the alphabet every
year since. (The letter for 2005 is "U".)

Every user is identified to RGTP by their email address. They are usually
identified to the other users by a string known as their "grogname". (These
are usually fanciful, and regular contests are held as to the best ones.)

Every action which causes a state change on an RGTP server is given a
monotonically increasing sequence number. Most actions are also given
timestamps. These are in seconds since midnight UTC, 1 January 1970.

=head1 CONSTRUCTOR

=over 4

=item new ([ OPTIONS ])

This is the constructor for a new Net::RGTP object. C<OPTIONS> are passed
in a hash-like fashion, using key and value pairs. Possible options are:

B<Host> - the name of the RGTP server to connect to. If this is omitted,
it will default to C<rgtp-serv.groggs.group.cam.ac.uk>.

B<Port> - the port number to connect to. If this is omitted, it will default
to 1471, the IANA standard number for RGTP.

B<Debug> - set this to 1 if you want the traffic between the server and
client to be printed to stderr. This does not print the contents of
files (e.g. the index, or items) as they transfer.

=back

=head1 METHODS

=over 4

=item login ([USERID, [SECRET]])

Logs in to the RGTP server.

USERID is the user identity to use on the RGTP server, typically an
email address. If left blank it will default to "guest".

SECRET is the shared-secret which is sent out by mail. It must either be a
hex string with an even number of digits, or undef.
It should be undef only if you are expecting not to have to go through
authentication (for example, on many RGTP servers the account called "guest"
needs no authentication step).

This method returns the current access level, in the format returned by
the C<access_level> method. The method returns C<undef> on failure, and
sets C<$@> to an appropriate message.

=item access_level

Returns the current access level. 0 means only the message of the day
may be read. 1 means the index and any item may be read, but nothing
may be written. 2 means that items may be posted to. 3 means that the
contents of the items, including posts made by other users, may be
edited.

=item latest_seq

Returns the highest sequence number which has been seen in the index
of this server. This may be C<undef> if we have not downloaded the
index (or if the server is entirely empty).

=item motd

Returns a hashref containing only the key B<posts>, which maps to an
arrayref containing only one element, a hashref which contains three
keys:

B<seq>: the sequence number of the message of the day;

B<text>: the text of the message of the day; and

B<timestamp>: the time the message of the day was last set.

The reason for the baroque formatting is that it matches the format
of the response of the C<item> method.

Returns C<undef> if there is no message of the day.

=item item(ITEMID)

Returns a hashref which may if applicable contain the keys:

B<parent>, which is the itemid of the given item's parent;

B<child>, which is the itemid of the given item's child; 

B<subject>, which is the subject line of the given item;

B<reply>, which is the sequence number of the most recent reply
to the given item; and

B<edit>, which is the sequence number of the most recent edit.
(That is, an edit by an editor, not an ordinary reply.)

The hashref will always contain a key B<posts>. This maps to an
arrayref of hashrefs, each representing a post to this item.
Each hashref may if applicable contain the keys:

B<seq>, which is the sequence number of this post;

B<timestamp>, which is the timestamp of this post;

B<grogname>, which is the grogname of the poster; and

B<poster>, which is the user ID of the poster (that is, their email address).

There will also always be a key B<text>, which contains the text of the post.

C<item> returns C<undef> if the item does not exist.

As a special case, C<item("motd")> is equivalent to calling the C<motd> method.

=item quick_item(ITEMID)

Similar to the C<item> method, but the hashref returned
does not contain the key B<posts>. Use this method if you
only need to know, for example, the item's most recent
sequence number or its subject line. It executes many times
faster than the C<item> method, because the content of the
item does not need to be transferred.

This implements the RGTP function "STAT". The method is not
called C<stat> because that is a perl builtin.

=item items

Returns a hashref describing every item on the current server.

The keys of the hashref are the itemids of the several items,
except for the key "motd", which describes the message of the day.
Each key maps to a hash describing the item. The keys of this hash are:

B<subject>: the subject line of the item. This may be truncated by
the RGTP server; you may find the exact subject line using the C<item>
method.

B<posts>: a count of posts.

B<timestamp>: the timestamp of the most recent change to this item.

B<seq>: the sequence number of the most recent change to this item.

B<parent>: the itemid of the parent of this item. Exists only for items
which have a parent.

B<child>: the itemid of the child of this item. Exists only for items
which have a child.

This method may take a long time to execute on popular RGTP servers
the first time it is called. This is because it has to download the
entire index. Subsequent calls will use cached data and will be faster.
See also the C<state> method.

=item state([STATE])

This method exists because the C<items> method is slow on first use.
(Over my home connection, for the main GROGGS server, it takes about
forty seconds). When called with no arguments, C<state> returns a
scalar describing the state of C<items>'s cache. When called with
this scalar as argument, it re-fills the cache with this data. This
scalar can be seralised so that the advantages of caching can be
gained between sessions.

=item post(WHERE, WHAT, [OPTS])

Adds some content to the RGTP board.

WHAT is a block of text wrapped at 80 columns. I recommend the use
of Text::ASCIITable::Wrap to format arbitrary text in this way.

WHERE can be one of three things:

B<The string C<new>.> In this case WHAT is posted as a new item
on the server.

B<A valid and existing itemid>. In this case WHAT is appended as
a reply to the given item.

B<The string C<continue>.> This only works when the continuation
flag is set (see CONTINUATIONS below). WHAT is posted as the
first entry in a continuation item.

C<OPTIONS> are passed in a hash-like fashion, using key and value
pairs. Possible options are:

B<Seq>. The sequence number of the last known reply to this item.
Ignored when WHAT is C<new> or C<continue>. If this is undefined,
the sequence number will not be checked. See COLLISIONS below.

B<Grogname>. The grogname to use when posting. If this is undefined,
no grogname will be used. Grognames which are too long may cause
the method to return an error.

B<Title>. The title to use for the new item. Required when WHAT is
C<new> or C<continue>, and ignored at all other times.

On success, in list context, this method returns a list consisting
of the itemid followed by the sequence number of the post. In
scalar context, it returns only the itemid.

The method returns C<undef> on failure, and sets C<$@> to an
appropriate message. It also causes the functions C<item_is_full>
and C<item_is_grown> to return values which represent the reason
it failed.

=item item_is_full

Returns true iff the most recent call to C<post> failed because the
target item had gone into a continuation. This is known as the
"continuation flag": see CONTINUATIONS below.

=item item_has_grown

Returns true iff the most recent call to C<post> failed because of
a collision in the target item. See COLLISIONS below.

=head1 CONTINUATIONS

Items have a maximum size. Thus after a certain amount of posting to
any given item, it will cease to be possible to post any more content.
When this happens, C<post> will return C<undef>, and set the
"continuation flag", which may be inspected using the C<item_is_full>
method.

When the flag is set, and only when the flag is set, it is possible
to call C<post> again with the WHERE parameter set to C<"continue">.
This creates a continuation item following on from the item you were
originally trying to post to.

=head1 COLLISIONS

Because RGTP is not threaded, most users want to check, when they
reply to an item, that it has not been replied to already while they
were composing their reply. The lack of a built-in way to do this is
a fundamental flaw in RGTP; most clients get around the problem by
doing a STAT (equivalent to our C<quick_item> method) immediately
before posting, and comparing the sequence number given to one taken
before the reply was composed. Net::RGTP provides an easy way to
accomplish this: setting the B<Seq> option to the C<post> command.
If this check fails, C<post> will return C<undef> and C<item_has_grown>
will subsequently return true.

However, any such mechanism introduces a race condition into the
protocol. The chance of a race occurring is slight, and the problems
caused thereby are small, but programmers should be aware of it.

The only case when RGTP does tell us when an item has been updated
is when an item has gone into a continuation. In this case C<post>
and C<item_has_grown> will behave as if B<Seq> had been specified,
even if it was not.

=head1 UNIMPLEMENTED

The following aspects of RGTP have not been implemented. This will
be addressed in a later revision:

=over 4

=item Edit log

Viewing the log of editors' changes to the board.

=item Registration

Creating new user accounts.

=item Editing

Using superuser powers to modify other people's comments.

=head1 AUTHOR

Thomas Thurman <marnanel@marnanel.org>

=head1 CREDITS

Firinel Thurman - for being there to bounce ideas off, and, well, everything.

John Stark - for inventing GROGGS.

Ian Jackson - for inventing RGTP.

Tony Finch - whose RGTP to Atom converter made the idea of this module click
for me.

=head1 SEE ALSO

The RGTP protocol, at
 http://www.groggs.group.cam.ac.uk/protocol.txt .

The GROGGS home page, at
 http://www.groggs.group.cam.ac.uk/ .

Yarrow, a CGI RGTP client, at
 http://rgtp.thurman.org.uk/gossip/groggs/browse .

GREED, an Emacs RGTP client, at
 http://www.chiark.greenend.org.uk/~owend/free/GREED.html .

=head1 COPYRIGHT

Copyright (c) 2005 Thomas Thurman. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
