#!/usr/bin/perl -w -T
# -*- cperl -*-
package Net::Server::POP3;
use strict;

my %parameters; my @message; my @deleted;

my $debug = 0;  # Set this to 1 to generate more debugging info.
#use Data::Dumper; $|++; # Uncomment this stuff for debugging.

my $EOL = "\n"; # Change to "\r\n" if you don't get a full CRLF from
                # "\n".  I'm investigating how to fix this so it works
                # on all versions of perl on all platforms.
                # Meanwhile, you can also pass EOL to new() or
                # startserver() and it will change this default.

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.0008;
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw (startserver op user);
	%EXPORT_TAGS = ();
}

sub nop {return}; # Used as default for optional callbacks.

my %op; my %user;

sub startserver {
  my $self = shift;
  %op = (%parameters, @_);
  my %serveropts; %serveropts = %{$op{serveropts}} if exists $op{serveropts};
  $op{port}         ||= 110;
  $op{servertype}   ||= 'Fork';
  $op{authenticate} ||= \&nop; # Authorizes nobody; you must provide the callback to change this.
  $op{delete}       ||= \&nop; # It is strongly recommended to provide a delete callback.
  $op{connect}      ||= \&nop;
  $op{disconnect}   ||= \&nop;
  $op{welcome}      ||= "Welcome to Net::Server::POP3 $VERSION.  Some stuff may not work yet.";
  warn "WARNING: The welcome message is longer than 506 bytes in violation of RFC 1939.\n" if length $op{welcome} > 506;
  $op{linetimeout}  ||= 600;
  $EOL = $op{EOL} if exists $op{EOL};       # Should be either "\n" or "\r\n",
                                            # depending on something
                                            # system-dependent that I haven't
                                            # yet nailed down.
  $debug = $op{DEBUG} if exists $op{DEBUG}; # Default is 0, but calling code can
                                            # set it to undef if desired.

  exists $op{list} or die "The list callback is required."; # Should these croak instead of die?
  exists $op{retrieve} or die "The retrieve callback is required.";

  # use Net::Server::Fork; # We want to fix this to use $op{servertype}
  eval "use Net::Server::$op{servertype}";
  push @ISA, "Net::Server::$op{servertype}";
  Net::Server::POP3->run(port => $op{port}, %serveropts);
}

sub messagesize {
  my ($msgnum) = @_;
  if (ref $op{size}) {
    return $op{size}->($user{name}, $message[$msgnum-1]);
  } else {
    return length($op{retrieve}->($user{name}, $message[$msgnum-1]));
    # This might harm efficiency and kill performance.
  }
}

sub boxsize {
  my $totalsize = 0; my $msgnum;
  for (@_) { $totalsize += messagesize(++$msgnum) }
  return $totalsize;
}

sub scanlisting {
  # returns a scan listing for each message number in @_

  warn "scanlisting @_\n" if $debug;
  # In order to simplify parsing, all POP3 servers are required to use
  # a certain format for scan listings.  A scan listing consists of
  # the message-number of the message, followed by a single space and
  # the exact size of the message in octets.
  my $msgnum = shift;
  my $size = messagesize($msgnum);
  die "Message $msgnum (user $user{name}) has no size!$/" unless ($size>0);
  return "$msgnum $size";
}

sub process_request { # The name of this sub is magic for Net::Server.
    my $self = shift;

    $op{connect}->();
    eval {
      print "+OK $op{welcome}$EOL";

      local $SIG{ALRM} = sub { die "Timed Out!\n" };
      my $timeout = $op{linetimeout};

      my $previous_alarm = alarm($timeout);
      my $state = 0; # 0 = not authenticated.  1 = authenticated.
      while (<STDIN>) {
        chomp;
        if ($state) {
          # We _are_ authenticated.  Let user do stuff.
          # The RFC calls this the Transaction State.
          if (/^STAT/i) {
            print "+OK ".(scalar @message)." ".boxsize(@message).$EOL;
          } elsif (/^VERSION/i) {
            print "+OK Net::Server::POP3 $VERSION$EOL";
          } elsif (/^LIST\s*(\d*)/i) {
            my $msgnum = $1;
            if ($msgnum) {
              # If an argument was given and the POP3 server issues a
              # response with a line containing information for that
              # message.  This line is called a "scan listing" for
              # that message.
              if ($msgnum <= @message) {
                print "+OK " . scanlisting($msgnum).$EOL;
              } else {
                # Most clients won't even try this.
                print "-ERR Cannot find message $msgnum (only ".@message." in drop)$EOL";
              }
            } else {
              # If no argument was given and the POP3 server issues a
              # positive response, then the response given is
              # multi-line.  After the initial +OK, for each message
              # in the maildrop, the POP3 server responds with a line
              # containing information for that message.  This line is
              # also called a "scan listing" for that message.  If
              # there are no messages in the maildrop, then the POP3
              # server responds with no scan listings--it issues a
              # positive response followed by a line containing a
              # termination octet and a CRLF pair.
              print "+OK scan listing follows$EOL";
              for (@message) {
                ++$msgnum;
                if (not $deleted[$msgnum-1]) {
                  # RFC1939 sez: Note that messages marked as deleted are not listed.
                  print scanlisting($msgnum).$EOL;
                }
              }
              print ".$EOL";
            }
          } elsif (/^UIDL\s*(\d*)/i) {
            my $msgnum = $1;
            if ($msgnum) {
              # If an argument was given and the POP3 server issues a
              # positive response with a line containing information
              # for that message.  This line is called a "unique-id
              # listing" for that message.
              if ($msgnum <= @message) {
                print "+OK $msgnum " . $message[$msgnum-1] . $EOL;
              } else {
                # Most clients won't even try this.
                print "-ERR Cannot find message $msgnum (only ".@message." in drop)$EOL";
              }
            } else {
              # If no argument was given and the POP3 server issues a
              # positive response, then the response given is
              # multi-line.  After the initial +OK, for each message
              # in the maildrop, the POP3 server responds with a line
              # containing information for that message.  This line is
              # called a "unique-id listing" for that message.
              print "+OK message-id listing follows$EOL";
              for (@message) {
                ++$msgnum;
                if (not $deleted[$msgnum-1]) {
                  print "$msgnum $_$EOL";
                }
              }
              print ".$EOL";
            }
          } elsif (/^TOP\s*(\d+)\s*(\d+)/i) {
            # RFC lists TOP as optional, but Mozilla Messenger seems to require it.
            my ($msgnum, $toplines) = ($1, $2);
            # If the POP3 server issues a positive response, then the
            # response given is multi-line.  After the initial +OK,
            # the POP3 server sends the headers of the message, the
            # blank line separating the headers from the body, and
            # then the number of lines of the indicated message's
            # body, being careful to byte-stuff the termination
            # character (as with all multi-line responses).
            # Note that if the number of lines requested by the POP3
            # client is greater than than the number of lines in the
            # body, then the POP3 server sends the entire message.
            my ($head, $body) = split /\n\n/, $op{retrieve}->($user{name}, $message[$msgnum-1]), 2;
            my ($hl, $bl) = (length $head, length $body);
            print "+OK top of message follows ($hl octets in head and $bl octets in body up to $toplines lines)$EOL";
            for (split /\n/m, $head) {
              chomp;
              s/^/./ if /^[.]/;
              print "$_$EOL";
            }
            print "$EOL";
            my $lnum;
            for (split /\n/m, $body) {
              chomp;
              s/^/./ if /^[.]/;
              print "$_$EOL" if ++$lnum <= $toplines;
            }
            print ".$EOL";
          } elsif (/^RETR\s*(\d*)/i) {
            my ($msgnum) = $1;
            if ($msgnum <= @message) {
              print "+OK sending $msgnum " . $message[$msgnum-1] . "$EOL";
              warn "Sending message $msgnum:\n" if $debug;
              warn "\@message is as follows: " . Dumper(\@message) . "\n" if $debug>1;
              my $msgid = $message[$msgnum-1];
              warn "message id is $msgid\n" if $debug;
              die "No retrieve callback\n" unless ref $op{retrieve};
              my $msg = $op{retrieve}->($user{name}, $msgid);
              warn "Retrieved message\n" if $debug;
              if (not $msg =~ /\n\n/m) {  warn "Message $msgnum ($msgid) seems very wrong:\n$msg\n"; die "Suffering and Pain!\n"; }
              warn "Message is as follows: " . Dumper($msg) . "\n" if $debug>1;
              for (split /\n/, $msg) {
                chomp;
                s/^/./ if /^[.]/;
                print "$_$EOL";
                warn "$_\n" if $debug>2;
              }
              print ".$EOL";
            } else {
              # Most clients won't even try this.
              print "-ERR Cannot find message $msgnum (only ".@message." in drop)$EOL";
            }
          } elsif (/^DELE\s*(\d*)/i) {
            my ($msgnum) = $1;
            if ($msgnum <= @message) {
              $deleted[$msgnum-1]++;
              # Any future reference to the message-number associated
              # with the message in a POP3 command generates an error,
              # according to the RFC, but in practice clients should
              # simply not do that, so it can be something we
              # implement later, after most stuff works.
              print "+OK marking message number $msgnum for later deletion.$EOL";
              # The POP3 server does not actually delete the message
              # until the POP3 session enters the UPDATE state.
            } else {
              # Most clients won't even try this.
              print "-ERR Cannot find message $msgnum (only ".@message." in drop)$EOL";
            }
          } elsif (/^QUIT/i) {
            my $msgnum = 0;
            for (@message) {
              if ($deleted[(++$msgnum)-1]) {
                if ($op{delete}) {
                  # Yes, this is optional so that highly minimalistic
                  # implementations can skip it, but any serious mail
                  # server will obviously need to supply the delete
                  # callback.
                  $op{delete}->($user{name}, $message[$msgnum-1]);
                }
              }
            }
            print "+OK Bye, closing connection...$EOL";
            $op{disconnect}->();
            return 0;
          } elsif (/^NOOP/) {
            print "+OK nothing to do.$EOL";
          } elsif (/^RSET/) {
            @deleted = ();
            print "+OK now no messages are marked for deletion at end of session.$EOL";
          } elsif (/^CAPA/) {
            print capabilities(1); # The 1 indicates we are in the transaction state.
          } else {
            warn "Client said \"$_\" (which I do not understand in the transaction state)\n" if defined $debug; # even if it's at level 0.  undef it if you don't want this.
            print "-ERR That must be something I have not implemented yet.$EOL";
          }
        } else {
          # We're not authenticated yet.  The RFC calls this the Authentication State.
          if (/^QUIT/i) {
            print "+OK Bye, closing connection...$EOL";
            $op{disconnect}->();
            return 0;
          } elsif (/^VERSION/i) {
            print "+OK Net::Server::POP3 $VERSION$EOL";
          } elsif (/^USER\s*(\S*)/i) {
            $user{name} = $1;  delete $user{pass};
            print "+OK $user{name} knows where his towel is; use PASS to authenticate$EOL";
          } elsif (/^PASS\s*(.*?)\s*$/i) {
            $user{pass} = $1;
            $user{peer} = $self->{server}->{peeraddr}; # Todo: Fix this to get IP address from Net::Server.
            $user{peer} = Dumper($self->{server}) if $debug;
            if ($user{name}) {
              if ($op{authenticate}->(@user{'name','pass','peer'})) {
                $state = 1;
                @message = $op{list}->($user{name});
                warn "Have maildrop: " . Dumper(\@message) . "\n" if $debug>1;
                print "+OK $user{name}'s maildrop has ".@message." messages (".boxsize(@message)." octets)$EOL";
              } else {
                delete $user{name};
                print "-ERR Unable to lock maildrop at this time with that auth info$EOL";
              }
            } else {
              print "-ERR You can only use PASS right after USER$EOL";
            }
          } elsif (/^APOP/) {
            print "-ERR APOP authentication not yet implemented, try USER/PASS$EOL";
          } elsif (/^CAPA/) {
            print capabilities(0); # The zero means we're not authenticated yet.
          } else {
            warn "Client said \"$_\" (which I do not understand in the unauthenticated state)\n" if defined $debug;
            print "-ERR That must be something I have not implemented yet, or you need to authenticate.$EOL";
          }
        }
        alarm($timeout);
      }
      alarm($previous_alarm);

    };

      if ($@=~/timed out/i) {
      print STDOUT "-ERR Timed Out.$EOL";
      return;
    }
}

########################################### main pod documentation begin ##

=head1 NAME

Net::Server::POP3 - The Server Side of the POP3 Protocol for email

=head1 SYNOPSIS

  use Net::Server::POP3;
  my $server = Net::Server::POP3->new(
    severopts    => \%options,
    authenticate => \&auth,
    list         => \&list,
    retrieve     => \&retrieve,
    delete       => \&delete,
    size         => \&size,
    welcome      => "Welcome to my mail server.",
  );
  $server->startserver();

=head1 DESCRIPTION

Net::Server::POP3 is intended to handle the nitty-gritty details of
talking to mail clients, so that in writing a custom POP3 server you
don't have to actually read RFC documents.  The backend things (such
as where mail comes from and what messages are in the user's mailbox
at any given time) are left up to your code (or another module), but
this module handles the POP3 protocol for you.  Also, the details of
listening for client connections and so on are handled by Net::Server.

This approach allows for some flexibility.  Your code may choose to
generate messages on the fly, proxy them from another mail server,
retrieve them from a local maildir or mailbox of some kind, or
whatever.  See the sample scripts in this distribution for examples.

This code is still very much beta.  There are known bugs.  Some things
(e.g., APOP) haven't even been implemented yet.  You have been warned.
See the Bugs section for details.

The code as it stands now works, for some definition of "works".  With
the included simpletest.pl script I have successfully served test
messages that I have retrieved with Mozilla Mail/News.  Additionally,
with the included proxytest.pl script I have successfully proxied mail
from an ISP mail server to a client.  However, much remains to be done.

It is strongly recommended to run with Taint checking enabled.

These are the RFCs that I know about and intend to implement:

=over

=item http://www.faqs.org/rfcs/rfc1939.html

=item http://www.faqs.org/rfcs/rfc2449.html


=back

If you know of any other RFCs that seem pertinent, let me know.

=head1 USAGE

This module is designed to be the server/daemon itself and so to
handle all of the communication to/from the client(s).  The actual
details of obtaining, storing, and keeping track of messages are left
to other modules or to the user's own code.  (See the sample scripts
simpletest.pl (simple) and proxytest.pl (somewhat more involved) in
this distribution for examples.)

The main method is startserver(), which starts the server.  The
following named arguments may be passed either to new() or to
startserver().  All callbacks should be passed as coderefs.
If you pass an argument to new() and then pass an argument of
the same name to startserver(), the one passed to startserver()
overrides the one passed to new().  stopserver() has not been
implemented yet and so neither has restartserver(), but they
are planned for an eventual future version.

=over

=item EOL

A string containing the characters that should be printed on a socket
to cause perl to emit an RFC-compliant CRLF.  On some systems this may
need to be set to "\r\n".  The default is "\n", which is what it needs
to be on my development platform (Linux Mandrake 9.2).  Setting it to
the wrong thing causes breakage either way, so experiment.  (Fixing
this to Just Work(TM) on all systems is on the Todo list.)

The EOL string is optional; you only need to specify it if "\n" is the
wrong value.

=item port

The port number to listen on.  110 is the default.  The user or group
you are running as needs permission to listen on this port.

The port number is optional.  You only need to specify it if you want
to listen on a different port than 110.

=item servertype

A type of server implemented by Net::Server (q.v.)  The default is
'Fork', which is suitable for installations with a small number of
users.

The servertype is optional.  You only need to specify it if you want
to use a different type other than 'Fork'.

=item serveropts

A hashref containing extra named arguments to pass to Net::Server.
Particularly recommended for security reasons are user, group, and
chroot.  See the docs for Net::Server for more information.

The serveropts hashref is optional.  You only need to supply it if you
have optional arguments to pass through to Net::Server.

=item connect

This callback, if supplied, will be called when a client connects.
This is the recommended place to allocate resources such as a database
connection handle.

The connect callback is optional; you only need to supply it if you
have setup to do when a client connects.

=item disconnect

This callback, if supplied, is called when the client disconnects.  If
there is any cleanup to do, this is the place to do it.  Note that
message deletion should not be handled here, but in the delete callback.

The disconnect callback is optional; you only need to supply it if you
have cleanup to do when a client disconnects.

=item authenticate

The authenticate callback is passed a username, password, and IP
address.  If the username and password are valid and the user is
allowed to connect from that address and authenticate by the USER/PASS
method, then the callback should try to get a changelock on the
mailbox and return 1 if successful; it must return something other
than 1 if any of that fails.  (Returning 0 does not specify the
details of what went wrong; other values may in future versions have
particular meanings.)

The authenticate callback is technically optional, but you need to
supply it if you want any users to be able to log in using the USER
and PASS commands.

=item apop

Optional callback for handling APOP auth.  If the user attempts APOP
auth and this callback exists, it will be passed the username, the
digest sent by the user, and the server greeting.  If the user's
digest is indeed the MD5 digest of the concatenation of the server
greeting and the shared secret for that user, then the callback
should attempt to lock the mailbox and return true if successful;
otherwise, return false.

The apop callback is only needed if you want to supply APOP
authentication.

This is not implemented yet, but I plan to implement it in an
eventual future version.

=item list

The list callback, given a valid, authenticated username, must return
a list of message-ids of available messages.  (Most implementations
will ingore the username, since they will already be locked in to the
correct mailbox after authentication.  That's fine.  The username is
passed as a help for minimalist implementations.)

The list callback is required.

=item size

The size callback if it exists will be passed a valid, authenticated
username and a message id (from the list returned by the list
callback) and must return the message size in octets.  If the size
callback does not exist, the size will be calculated using the
retrieve callback, which is inefficient.  Providing the size callback
will prevent the retrieve callback from being called unnecessarily,
thus improving performance.  (Most implementations will ingore the
username, since they will already be locked in to the correct mailbox
after authentication.  That's fine.  The username is passed as a help
for minimalist implementations.)

Note that very early versions passed only the message id, not the
username, to the size callback.  This changed in 0.0005, breaking
backward-compatibility for the size callback.

The size callback is optional.  You only need to provide it if you
care about performance.

=item retrieve

The retrieve callback must accept a valid, authenticated username and
a message-id (from the list returned by the list callback) and must
return the message as a string.  (Most implementations will ingore the
username, since they will already be locked in to the correct mailbox
after authentication.  That's fine.  The username is passed as a help
for minimalist implementations.)

The retrieve callback is required.

=item delete

The delete callback gets called with a valid, authenticated username
and a message-id that the user/client has asked to delete.  (Most
implementations will ingore the username, since they will already be
locked in to the correct mailbox after authentication.  That's fine.
The username is passed as a help for minimalist implementations.)

The delete callback is only called in cases where the POP3 protocol
says the message should actually be deleted.  If the connection
terminates abnormally before entering the UPDATE state, the callback
is not called, so code using this module does not need to concern
itself with marking and unmarking for deletion.  When called, it can
do whatever it wants, such as actually delete the message, archive it
permanently, mark it as no longer to be given to this specific user,
or whatever.

This callback is technically optional, but you'll need to supply one
if you want to know when to remove messages from the user's maildrop.

=item welcome

This string is used as the welcome string sent to the client upon
connection.  It must not be longer than 506 bytes, for arcane reasons
involving RFC1939.  (startserver will generate a warning at runtime if
it is too long.)

The welcome string is optional; a default welcome is supplied.

=item logindelay

If a number is given, it will be announced in the capabilities list as
the minimum delay (in seconds) between successive logins by the same
user (which applies to any user).  This does NOT enforce the delay; it
only causes it to be announced in the capabilities list.  The
authenticate callback is responsible for enforcement of the delay.
The delay SHOULD be enforced if it is announced (RFC 2449).

If the delay may vary per user, logindelay should be a callback
routine.  If the callback is passed no arguments, it is being asked
for the maximum delay for all users; if it is passed an argument, this
will be a valid, authenticated username and the callback should return
the delay for that particular user.  Either way, the return value
should be a number of seconds.  Again, this does NOT enforce the
delay; it only causes it to be announced in the capabilities list.
(Some clients may not even ask for the capabilities list, if they do
not implement POP3 Extensions (RFC 2449).)

The default is not to announce any particular delay.

=item expiretime

If a number or the string 'NEVER' is given, it will be announced in
the capabilities list as the length of time a message may remain on
the server before it expires and may be automatically deleted by the
server.  (The number is a whole number of days.)

This does NOT actually delete anything; it just announces the
timeframe to the client.  Clients that do not support POP3 Extensions
will not get this announcement.  'NEVER' means the server will never
expire messages; 0 means that expiration is immanent and the client
should not count on leaving messages on the server.  0 should be
announced for example if the mere act of retrieving a message may
cause it to expire shortly afterward.

If the message expiration time may vary by user, expiretime should be
a callback routine.  If the callback is passed no arguments, it is
being asked for the minimum expiration time for all users, which it
should return (as a whole number of days; 0 is acceptable); if it is
passed an argument, this will be a valid, authenticated username and
the callback should return the expiration time for this particular
user, either as a whole number of days or the string 'NEVER'.

The default is not to announce an expiration time.

=item DEBUG

Set the level of debugging information desired on standard output.
undef means no debug info at all.  0 means only warn when the client
uses commands that are not understood.  A value of 1 produces various
other information about functions that are being called, arguments
they are passed, and so on.  A value of 2 also uses Data::Dumper to
show the state of certain data structures at various times, possibly
including entire messages, possibly more than once per message.  This
can get really verbose.  A value of 3 is even more verbose and really
doesn't add anything for debugging your code.  (Level 3 is intended
for debugging the module itself.  Actually, all of it was mainly
intended for that originally, but the lower levels also proved useful
for debugging sample scripts.)

The DEBUG level is optional.  The default is 0.

=item linetimeout

Give the mail client (or user) this many seconds to type or send each
line.  My reading of RFC1939 is that this shouldn't be less than ten
minutes (at least, between commands), but Net::Server::POP3 does not
enforce this minimum.

The linetimeout is optional.  The default is currently 600 (ten
minutes), the minimum specified by the RFC.  The default value may
change in a future version.

=back

=head1 REQUIRES

Net::Server, Exporter

=head1 BUGS

=over

=item line endings

Depending on your platform and possibly your perl version, you might
need to set the EOL to "\r\n" instead of the default "\n".  However,
if your perl version already handles this the way mine does (Linux
Mandrake 9.2), setting it to "\r\n" will break it, resulting in the
mail client only seeing the first header you send as a header and
viewing the rest of the headers as part of the body, which is ugly; in
that case you should use "\n".  You can now pass an EOL parameter to
new or to startserver for this, until I figure out how to fix it for
real.  The default is "\n" if you don't specify.

=item client IP address

The authenticate callback was not passed the client's IP address as
documented, but I think this is fixed now.

=item APOP is not implemented yet.

=item stopserver and restartserver are not implemented

For now, the only way to stop the server is to kill it.  Actually,
this may not be true; I'm still investigating this stuff about the
Net::Server module.

=item UIDL

The UIDL implementation uses the message-id as the unique id, rather
than calculating a hash as suggested by RFC 1939.  In practice, this
seems to be what my ISP's mail server does (it calls itself
InterMail), which has worked with every client I've thrown at it, so
it should be mostly okay, but it's not strictly up to spec I think and
may be changed in a later version.  I intend to investigate what other
major POP3 servers do in this regard before making any changes; if you
happen to know e.g. what the POP3 servers do that are usually used
with Postfix, Exim, or Qmail, et cetera, drop me a line and let me
know.  Data about what the POP3 servers used by various ISPs do would
also be appreciated.

=item threads

The issue of thread safety has not even been considered, other than to
include this warning that it has not been considered.  If someone who
actually has experience with threaded programming wants to look it
over, that would be great; otherwise, I may try to get to it
eventually, but for now it's several items down the Todo list.

=item character handling

My code all assumes that each character is stored in one byte.  I
suspect most mail servers do this, but if your code that uses the
module produces any Unicode strings, this could make issues.  The
sample proxy modules are naively assuming that Mail::POP3Client
returns strings with octet symantics; I do not know whether this is
actually the case.  At minimum, this could cause the sizes of the
messages to be reported incorrectly (e.g. by LIST).

=item Caveat user

There may be other bugs as well; this is not release-quality code yet.
Significant changes may be made to the code interface before release
quality is reached, so if you use this module now you may have to
change your code when you upgrade.

The Todo list is long, and contributions are welcome, especially code
but also documentation, sample scripts, or other information such as
how the module works with various clients, what platforms and perl
versions need which setting for EOL (and how to determine this at
runtime), what POP3 servers do what for the UIDL, ...

=back

=head1 SUPPORT

Use the source, Luke.  You can also contact the author with questions,
but the code is supplied on an as-is basis with no warranty.  I will
try to answer any questions, but this is spare-time stuff for me.

=head1 AUTHOR

	Jonadab the Unsightly One (Nathan Eady)
	jonadab@bright.net
	http://www.bright.net/~jonadab/

=head1 COPYRIGHT

This program is free software licensed under the terms of...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

Note that the modules (such as Net::Server) that are used by this
module or by the sample scripts are covered under their respective
license agreements and are not governed by the license of
Net::Server::POP3.

=head1 SEE ALSO

  perl(1)
  Net::Server http://search.cpan.org/search?query=Net::Server
  Mail::POP3Client http://search.cpan.org/search?query=Mail::POP3Client
  The simpletest.pl script included in the scripts directory in this distribution.
  The proxytest.pl script also included in the scripts directory in this distribution.

L<Net::Server|http://search.cpan.org/search?query=Net::Server>

L<Mail::POP3Client|http://search.cpan.org/search?query=Mail::POP3Client>

L<simpletest.pl|http://search.cpan.org/src/JONADAB/Net-Server-POP3-0.0008/scripts/simpletest.pl>

L<proxytest.pl|http://search.cpan.org/src/JONADAB/Net-Server-POP3-0.0008/scripts/proxytest.pl>

For a more minimalist framework with a different interface, see
L<Net::Server::POP3::Skeleton|http://perlmonks.org/index.pl?node_id=342754>

=cut

############################################# main pod documentation end ##

sub new
{
  ((my $class), %parameters) = @_;

  my $self = bless ({}, ref ($class) || $class);

  return ($self);
}

sub capabilities {
  my ($state) = @_; # 1 for transaction state, 0 for no.
  my $response = "+OK capability list follows.";
  my @capa = (
              'TOP',
              'USER',
              # 'SASL mechanisms', # SASL auth is specified in a separate RFC someplace.
              # 'RESP-CODES', # Response codes as specified in RFC 2449.
              # 'PIPELINING', # I *think* this should Just Work(TM),
              #               given the way Perl handles sockets, but
              #               I'm NOT sure, so I'm leaving this turned
              #               off for now.
              'UIDL',
              "IMPLEMENTATION Net::Server::POP3 version_$VERSION",
             );
  if (exists $op{logindelay}) {
    if (ref $op{logindelay}) { # It's a callback; the actual delay can vary by user...
      my $delay; if ($state) { # Transaction state.  Get the value for *this* user:
        $delay = $op{logindelay}->($user{name});
      } else { # Authentication state.  Get the max value for all users:
        $delay = ($op{logindelay}->() . " USER"); }
      push @capa, "LOGIN-DELAY $delay"
    } else { # A number:  it must be the same number for all users:
      push @capa, "LOGIN-DELAY $op{logindelay}"
    }
  }
  if (exists $op{expiretime}) {
    if (ref $op{expiretime}) { # It's a callback; the actual time can vary by user...
      my $expire; if ($state) { # Get the value for *this* user:
        $expire = $op{expiretime}->($user{name});
      } else { # We're not authenticated:  get the min value for all users:
        $expire = ($op{expiretime}->() . " USER");
      }
      push @capa, "EXPIRE $expire";
    } else { # It's the same number for all users:
      push @capa, "EXPIRE $op{expiretime}";
    }
  }
  return "$response$EOL".
    (join "$EOL", @capa)."$EOL.$EOL";
}

42; #this line is important and will help the module return a true value
__END__
