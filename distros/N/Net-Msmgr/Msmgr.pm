package Net::Msmgr;

use 5.006;
use strict;
use warnings;

require Exporter;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use URI::Escape;

use vars qw / $TRID $dalogin /;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'debug' => [ qw ( DEBUG_PACKET_SEND
				       DEBUG_PACKET_RECV
				       DEBUG_COMMAND_SEND
				       DEBUG_COMMAND_RECV
				       DEBUG_OPEN
				       DEBUG_CLOSE
				       DEBUG_CONFUSED
				       DEBUG_HANDLER
				       DEBUG_NOTIFICATION)  ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'debug'} }, qw { GetVersion8Response } );

our @EXPORT = qw();
our $VERSION = substr(q$Revision: 0.16 $,10);


use constant DEBUG_PACKET_SEND => 	    1;
use constant DEBUG_PACKET_RECV =>	    2;
use constant DEBUG_COMMAND_SEND =>	    4;
use constant DEBUG_COMMAND_RECV =>	    8;
use constant DEBUG_OPEN =>		   16;
use constant DEBUG_CLOSE =>		   32;
use constant DEBUG_CONFUSED =>		   64;
use constant DEBUG_HANDLER =>		  128;
use constant DEBUG_NOTIFICATION =>	  256;



$TRID = 0 ; 
$dalogin = undef;		# cache this for speedier connections

sub TRID
{
    $TRID++;
    return $TRID;
}

sub GetVersion8Response
{
    my $user = shift;
    my ($trid, $scheme, $state, $string )  = @_;
    my %challenge_part = map { split '=' } split(',', $string) ;


    unless ($dalogin)
    {
	my $ua = new LWP::UserAgent;
	my $response = $ua->get('https://nexus.passport.com/rdr/pprdr.asp');
	my %passport_urls =
	    map { split '=' } split(',',($response->headers->header('PassportURLs')));
	$dalogin = $passport_urls{'DALogin'};
    }

    warn "No dalogin" unless $dalogin;
    return  unless $dalogin;

    my $username = uri_escape($user->user);
    my $password = uri_escape($user->password);
    my $auth_string = 'Passport1.4 ' . join(',',
			   qq {OrgVerb=GET},
			   qq {OrgURL=$challenge_part{ru}} ,
			   qq {sign-in=$username},
			   qq {pwd=$password},
			   qq {lc=$challenge_part{lc}},
			   qq {id=$challenge_part{id}},
			   qq {tw=$challenge_part{tw}},
			   qq {fs=$challenge_part{fs}},
##			   qq {ru=$challenge_part{ru}},
			   qq {ct=$challenge_part{ct}},
			   qq {kpp=$challenge_part{kpp}},
			   qq {kv=$challenge_part{kv}},
			   qq {ver=$challenge_part{ver}},
			   qq {tpf=$challenge_part{tpf}} );

    my $ua = new LWP::UserAgent;
    my $request = new HTTP::Request ( GET => 'https://' . $dalogin );
    $request->headers->header('Authorization' => $auth_string);

    my $response = $ua->request($request);
    if ($response->is_success)
    {
	if (my $auth_info = $response->header('authentication-info'))
	{
	    $auth_info =~ m/(t=.*\$\$\&p=.*\$\$)/;
	    if (my $magic_string = $1)
	    {
		return $magic_string;
	    }
	}
    }
    return undef;
} 

1;

=pod

=head1 NAME

Net::Msmgr - Microsoft Network Chat Client Toolkit

This is the documentation for $Revision: 0.16 $

=head1 SYNOPSIS

 use Net::Msmgr;
 use Net::Msmgr::Sesssion;
 use Net::Msmgr::User;

 our $session = new Net::Msmgr::Session;
 our $user = new Net::Msmgr::User ( user => 'username@msn.com',
                             password => 'my_password' ) ;

 $session->user($user);
 $session->login_handler( sub { shift->Logout } ) ;
 $session->connect_handler ( ... ) ; 
 $session->Login;


=head1 OVERVIEW

This is a set of perl modules for encapsulating interactions with the
Microsoft Network "Messenger" chat system.  You might use it to
develop clients, or robots.  The components are, this module, Net::Msmgr, 
which contains some non-object helper routines (mostly the
authentication chain for using MSNP8 (Protocol version 8) and a
handful of manifest constants for debugging.

Other modules include:

=over

=item	Net::Msmgr::Session

Encapsulates the entirety of a session.

=item	Net::Msmgr::User

Holds user authentication credentials.

=item	Net::Msmgr::Command

Used to hold command objects sent to or received from the servers.

=item	Net::Msmgr::Connection

Used to encapsulate server connections.

=item	Net::Msmgr::Switchboard

Derived from Net::Msmgr::Connection

=item   Net::Msmgr::Conversation

A higher level view of conversation - contains (but is not) a Switchboard

=item	Net::Msmgr::Object

Pure base class from which all of the others are derived.  Direct from
the perltoot manpage.


=head1	SERVER PROTOCOL

The entire protocol consists of a series of discrete messages that are
passed between the client and the various servers that make up the
system.  Messages come in a variety of broad classes (Normal,
Asyncronous, and Payload), and those are subdivided into more specific
types (Transfer Requests, Chat Messages, State Change Notifications.)

There are three servers you will deal with during a basic session, the
Dispatch Server, which is a meta server to distribute inbound
sessions, the Notification Server, which will hold a single connection
for the life of the session, and Switchboard Servers, which you will hold
as many connections as you have chat groups active.  

Technically, there is no difference between the Dispatch Server and
the Notification Server, except that the Dispatch Server will
(historically) always refer you to a Notification Server.  There is
nothing in the protocol to prohibit a Notification Server from ALSO
refering you to a third Notification Server, although this author has
never seen that happen.

Because of this, we tend to think of the DS and the NS as dissimilar
entities, but there is no need for them to be so, and in the interest
of flexibility they are treated the same.  There is no limit, besides
end-user patience to how many XFR messages you can receive.

=head2 DISPATCH SERVER

This is the first-base server.  Your minimum action here is to request
a session, and act on the instructions from the server.

=head2 NOTIFICATION SERVER

This is the center of your session, and when you have connected here,
most (other) clients, and this library will consider you "connected"
to MSN Chat.  

=head2 SWITCHBOARD SERVER

To send or receive messages from other clients, there must be a
connection to one or more Switchboard Servers.  Each one of these
connections is a 'party line', and all users currently connected to
the same session (referenced by what the library calls a $ssid
Switchboard Session ID) will see all messages sent by any user.  The
number of users that can be attached to a SSID appears to be
reaosonably unlimited (on the order of dozens).

=head1 COMMAND SUMMARY

Here is a quick summary of all of the messages used in this library 
between the client and the servers.

=over

=item VER -- Version

Optionally sent from client to DS / NS for protocol version negotiation.

=item INF -- Information

Optionally sent from client to DS / NS, asking what Encryption
Technique to use.  In MSNP7 and lower, it is always MD5.  MSNP8 uses a
different technique, but does not use this command to negotiate it.
Go figure.

=item USR -- User Information

Used in two variants from client to server as part of
the login procedure, in a slightly different variant from server to client as
part of that same procedure, and again later during the authentication
with Switchboard Servers.

=item XFR -- Transfer

Used in one variant from server to client as part of
the login procedure, referring you from DS to NS.  Used again later
from client to server to request a connection to a switchboard server.

=item CHG -- Change

Sent from client to server to alter your 'presence' (online, out to lunch, etc.)

=item ILN -- Inital online

Sent from server to client in response to your first change to online
status, with a list of visible users already on the system.

=item SYN -- Synchonize

Optionally sent from client to server to request a download of all of your user lists.

=item GTC -- no known mnemonic

Part of the bundle of information sent from server to client, it
advises the client of a user-set preference for dealing with new
users.  It is stored on the server, but not acted on in any way.  Can
be sent as a command to the server to alter this setting.

=item BLP -- Blocking Preference

Part of the bundle of information sent from server to client as part
of a SYN.  Used by the server to determine behavior if an unkonwn user
attempts to invite you to a switchboard session.

=item PRP -- Personal Phone Number

Sent from server to client during SYN, and sent from client to server
to change the settings.  Designed to hold telephone numbers on the
server in URI-encoded strings, and a few variants to hold some mobile
device preferences.

=item LST -- List

Sent from server to client during SYN, and in resposne to a LST
command.  One variant for each of the four lists (Allow, Block, Forward
and Reverse) the server maintains for each client.

=item ADD -- Add

Sent from client to server to add a user to a list.  Echoed from
server to client with new list serial-number.  The server maintains
this serial-number, such that the client may cache the list locally.

=item REM -- Remove

Sent from client to server to remove a user from a list.

=item REA -- Rename

Sent from client to server to change the Friendly Name associated with
a user in your lists.  Also used to change your own friendly name.

=item MSG -- Message

Sent from DS/NS server to client at login, and sometimes for
administrative (shutdown) messages.  Also, the core of what this
protocol is about - sending messages to other users and receiving
messages from other users via Switchboard Servers.

=item ANS -- Answer

Sent from client to switchboard server in resposne to a switchboard
invitation.

=item IRO -- Initial Roster

Sent from switchboard to client upon connection to a switchboard
server informing client of other users attached to that switchboard
session.

=item CAL -- Call

Sent from client to switchboard to invite another user to join the
switchboard session.

=item OUT -- Out

Async command sent from client to NS/DS/SB server to terminate their session.  

=item NLN -- Online

Async command sent from NS to client to advise of another user coming online.

=item FLN -- Offline

Async command sent from NS to client to advise of another user going offline.

=item PNG -- Ping

Async command sent from client to NS to make sure it is still there.

=item QNG -- Pong

Async command sent from NS to client to acknowledge its presence.

=item RNG -- Ring

Async command sent from NS to client to advise of another user inviting you to a Switchboard Session.

=item JOI -- Join

Async command sent from SB to client to advise of another user joining a Switchboard Session.

=item BYE -- Bye

Async command sent from SB to client to advise of another user leaving a Switchboard Session.

=back

=head1 COMMAND FORMATS

Commands sent in the protocols come in three (and a theoretically
possible fourth) variants.  This library refers to them as Normal,
Async, and Payload.  

=head2 NORMAL COMMANDS

The vast bulk of commands are Normal, and each
one is tagged with a numeric identifier by the client.  This
identifier will be used by the server to correlate its responses to
your requests.  This library does not currently verify any of these
transaction identifiers (TRIDs), but does send each command with a
unique monotonically-increasing number.  Library users can feel free
to use the TRID in Normal messages as a unique identifier, within the
rules of the protocol.  (That is: Sometimes a single Normal command
from client to server will result in many related responses, all of
which will contain the TRID of that single request).

=head2 ASYNC COMMANDS

Another block of commands are those sent from server to client in
resposne to asyncronous events, such as users in your Forward List
changing their status, invitations by other users to Switchboard
Sessions, and users joining and leaving Switchboard Sessions.

=head2 PAYLOAD COMMANDS

The final type of command is that which contains message data.  This
library only (currently) supports one, the MSG command, which is used
to encapsulate messages from server to client, and peer to peer.

=head1 ASYNCRONOUS INPUT

The library user is responsible for dealing with non-blocking IO, and
there are several ways you might do this.  If you are writing a
Perl/Tk you would probably use fileevent, or you might want to use
Joshua Pritikin's Event package (which I use), or you can roll your
own with select and poll.  You could even use alarm and signals to
periodically sweep all of the inbound sessions.

To help you with this, there are a pair of handlers in the
Net::Msmgr::Session object, $session->connect_handler, and
$session->disconnect_handler - which are called just after the TCP
connect() call and just before the TCP close() call respectively.

Each of these will be called with a single pointer to the Net::Msmgr::Connection object.  

It is the users' responsibility to call $connection->_recv_message
whenever input is available on $connection->socket.  

With Tk this would be something like

 sub Connect_handler
 {
     my $connection = shift;
     $mainwindow->fileevent($connection->socket,
			    'readable',
			    sub { $connection->_recv_message });
 }
 $session->connect_hanlder(\&Connect_handler);
 $session->Login;
 MainLoop;

Under Joshua Pritikin's Event package, you might use 

 our %watcher;

 sub ConnectHandler
 {
    my ($connection) = @_;
    my $socket = $connection->socket;
    $watcher{$connection} = Event->io(fd => $socket,
				      cb => [ $connection , '_recv_message' ],
				      poll => 're',
				      desc => 'recv_watcher',
				      repeat => 1);
 }

 sub DisconnectHandler
 {
    my $connection = shift;
    $watcher{$connection}->cancel;
 }

 $session->connect_handler(\&ConnectHandler);
 $session->disconnect_handler(\&DisconnectHandler);


A third handler Net::Msmgr::Session::switchboard_handler() will be called
with a Net::Msmgr::Connection object and an ssid for each switchboard session
you are invited to, or instantiate through
Net::Msmgr::Session::ui_new_switchboard().


=cut


#
# $Log: Msmgr.pm,v $
# Revision 0.16  2003/08/07 00:01:59  lawrence
# Initial Release
#
#
