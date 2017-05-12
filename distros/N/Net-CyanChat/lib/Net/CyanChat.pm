package Net::CyanChat;

#------------------------------------------------------------------------------#
# Net::CyanChat - Perl interface for connecting to Cyan Worlds' chat room.     #
#------------------------------------------------------------------------------#
# POD documentation is at the very end of this source code.                    #
#------------------------------------------------------------------------------#

use strict;
use warnings;
use IO::Socket;
use IO::Select;

our $VERSION = '0.07';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {
		host      => 'cho.cyan.com', # Default CC Host
		port      => 1812,           # Default CC Port (1813=debugging)
		debug     => 0,              # Debug Mode
		proto     => 1,              # Use Protocol 1 (not 0)
		sock      => undef,          # Socket Object
		select    => undef,          # Select Object
		pinged    => 0,              # Last Ping Time
		refresh   => 60,             # Ping Rate = 60 Seconds
		nickname  => '',             # Our Nickname
		handlers  => {},             # Handlers
		connected => 0,              # Are We Connected?
		accepted  => 0,              # Logged in?
		who       => {},             # Who List
		special   => {},             # Special who List
		ignored   => {},             # Ignored List
		nicks     => {},             # Nickname Lookup Table
		@_,
	};

	# Protocol support numbers: 0 and 1.
	if ($self->{proto} < 0 || $self->{proto} > 1) {
		die "Unsupported protocol version: must be 0 or 1!";
	}

	bless ($self,$class);
	return $self;
}

sub version {
	my ($self) = @_;
	return $VERSION;
}

sub debug {
	my ($self,$msg) = @_;

	return unless $self->{debug} == 1;
	print "Net::CyanChat::debug // $msg\n";
}

sub send {
	my ($self,$data) = @_;

	# Send the data.
	if (defined $self->{sock}) {
		$self->debug (">>> $data\n");

		# Send true CrLf
		$self->{sock}->send ("$data\x0d\x0a") or do {
			# We've been disconnected!
			$self->{sock}->close();
			$self->{sock} = undef;
			$self->{select} = undef;
			$self->{connected} = 0;
			$self->{nick} = '';
			$self->{pinged} = 0;
			$self->{who} = {};
			$self->{nicks} = {};
			$self->_event ('Disconnected');
		};
	}
	else {
		warn "Could not send \"$data\" to CyanChat: connection not established!";
	}
}

sub setHandler {
	my ($self,$event,$code) = @_;

	# Set this handler.
	$self->{handlers}->{$event} = $code;
}

sub connect {
	my ($self) = @_;

	# Connect to CyanChat.
	$self->{sock} = new IO::Socket::INET (
		PeerAddr => $self->{host},
		PeerPort => $self->{port},
		Proto    => 'tcp',
	);

	# Error?
	if (!defined $self->{sock}) {
		$self->_event ('Error', "00|Connection Error", "Net::CyanChat Connection Error: $!");
		return undef;
	}

	# Create a select object.
	$self->{select} = IO::Select->new ($self->{sock});
	return 1;
}

sub start {
	my ($self) = @_;

	while (1) {
		$self->do_one_loop or last;
	}

	return undef;
}

sub login {
	my ($self,$nick) = @_;

	# Remove newline characters.
	$nick =~ s/[\x0d\x0a]//ig;

	if (length $nick > 0) {
		# Sign in.
		$self->send ("10|$nick");
		$self->{nickname} = $nick;
		return 1;
	}

	return undef;
}

sub logout {
	my ($self) = @_;

	return undef unless length $self->{nickname} > 0;
	$self->{nickname} = '';
	$self->{accepted} = 0;
	$self->send ("15");
	return 1;
}

sub sendMessage {
	my ($self,$msg) = @_;

	# Remove newline characters.
	$msg =~ s/[\x0d\x0a]//ig;

	# Send the message.
	return undef unless length $msg > 0;
	$self->send ("30|^1$msg");
	return 1;
}

sub sendPrivate {
	my ($self,$to,$msg) = @_;

	# Remove newline characters.
	$to  =~ s/[\x0d\x0a]//ig;
	$msg =~ s/[\x0d\x0a]//ig;

	return undef unless (length $to > 0 && length $msg > 0);
	# Get the user's full nick.
	my $nick = $self->{nicks}->{$to};

	# Send this user a message.
	$self->send ("20|$nick|^1$msg");
	return 1;
}

sub getBuddies {
	my ($self) = @_;

	# Return the buddylist.
	my $buddies = {};
	foreach my $key (keys %{$self->{who}}) {
		$buddies->{who}->{$key} = $self->{who}->{$key};
	}
	foreach my $key (keys %{$self->{special}}) {
		$buddies->{special}->{$key} = $self->{special}->{$key};
	}
	return $buddies;
}

sub getUsername {
	my ($self,$who) = @_;

	# Return this user's full name.
	return $self->{nicks}->{who}->{$who} || $self->{nicks}->{special}->{$who} || undef;
}
sub getFullName {
	my ($self,$who) = @_;

	# Alias for getUsername.
	return $self->getUsername ($who);
}

sub getAddress {
	my ($self,$who) = @_;

	# Return this user's address.
	return $self->{who}->{$who} || (
		exists $self->{special}->{$who} ? "Cyan Worlds" : undef
	) || undef;
}

sub protocol {
	my ($self) = @_;
	return $self->{proto};
}

sub nick {
	my ($self) = @_;

	return $self->{nickname};
}

sub ignore {
	my ($self,$who) = @_;

	# Remove newline characters.
	$who =~ s/[\x0d\x0a]//ig;

	# Ignore this user.
	return undef unless length $who > 0;
	$self->{ignored}->{$who} = 1;
	$self->send ("70|$who");
	return 1;
}
sub unignore {
	my ($self,$who) = @_;

	# Remove newline characters.
	$who =~ s/[\x0d\x0a]//ig;

	# Unignore this user.
	return undef unless length $who > 0;
	delete $self->{ignored}->{$who};
	$self->send ("70|$who");
	return 1;
}

sub authenticate {
	my ($self,$password) = @_;

	# Remove newline characters.
	$password =~ s/[\x0d\x0a]//ig;

	# Authenticate with a CC password.
	$self->send ("50|$password");
	return 1;
}

sub promote {
	my ($self,$user) = @_;

	# Remove newline characters.
	$user =~ s/[\x0d\x0a]//ig;

	# Promote this user to Special Guest.
	$self->send ("60|$user|4");
	return 1;
}

sub demote {
	my ($self,$user) = @_;

	# Remove newline characters.
	$user =~ s/[\x0d\x0a]//ig;

	# Demote this user.
	$self->send ("60|$user|0");
	return 1;
}

sub _event {
	my ($self,$event,@data) = @_;

	return unless exists $self->{handlers}->{$event};
	&{$self->{handlers}->{$event}} ($self,@data);
}

sub do_one_loop {
	my ($self) = @_;

	# Time to ping again?
	if ($self->{pinged} > 0) {
		# If connected...
		if ($self->{connected} == 1) {
			# If logged in...
			if ($self->{accepted} == 1) {
				# If refresh time has passed...
				if (time() - $self->{pinged} >= $self->{refresh}) {
					# To ping, send a private message to nobody.
					$self->send ("20||^1ping");
					$self->{pinged} = time();
				}
			}
		}
	}

	return undef unless defined $self->{select};

	# Loop with the server.
	my @ready = $self->{select}->can_read(.01);
	return 1 unless(@ready);

	foreach my $socket (@ready) {
		my $resp;
		$self->{sock}->recv ($resp,2048,0);
		my @in = split(/\n/, $resp);

		# The server has sent us a message!
		foreach my $said (@in) {
			$said =~ s/[\x0d\x0a]//ig;
			my ($command,@args) = split(/\|/, $said);

			$self->debug("<<< $said\n");

			# Go through the commands.
			if ($command == 10) {
				# 10 = Name is invalid.
				$self->_event ('Error', 10, "Your name is invalid.");
			}
			elsif ($command == 11) {
				# 11 = Name accepted.
				$self->{accepted} = 1;
				$self->_event ('Name_Accepted');
			}
			elsif ($command == 21) {
				# 21 = Private Message
				my $type = 0;
				my $fullNick = $args[0];
				my ($level) = $args[0] =~ /^(\d)/;
				$type = $args[1] =~ /^\^(\d)/;
				$args[0] =~ s/^(\d)//ig;
				$args[1] =~ s/^\^(\d)//ig;

				# Get the sender's nick and address.
				my ($nick,$addr) = split(/\,/, $args[0], 2);

				# Skip ignored users.
				next if exists $self->{ignored}->{$nick};

				shift (@args);
				my $text = join ('|',@args);

				# Call the event.
				$self->_event ('Private', {
					nick     => $nick,
					username => $fullNick,
					level    => $level,
					address  => $addr,
					message  => $text,
				});
			}
			elsif ($command == 31) {
				# 31 = Public Message.
				my $type = 1;
				my $fullNick = $args[0];
				my ($level) = $args[0] =~ /^(\d)/;
				($type) = $args[1] =~ /^\^(\d)/;
				$args[0] =~ s/^(\d)//i;
				$args[1] =~ s/^\^(\d)//i;

				# Get the sender's nick and address.
				my ($nick,$addr) = split(/\,/, $args[0], 2);

				# Skip ignored users.
				next if exists $self->{ignored}->{$nick};

				# Chop off spaces.
				$args[1] =~ s/^\s//ig;

				# Shift off data.
				shift (@args); # nickname
				my $text = join ('|',@args);

				# User has entered the room.
				if ($type == 2) {
					# Call the event.
					$self->_event ('Chat_Buddy_In', {
						nick     => $nick,
						username => $fullNick,
						level    => $level,
						address  => $addr,
						message  => $text,
					});
				}
				elsif ($type == 3) {
					# Call the event.
					$self->_event ('Chat_Buddy_Out', {
						nick     => $nick,
						username => $fullNick,
						level    => $level,
						address  => $addr,
						message  => $text,
					});
				}
				else {
					# Normal message.
					$self->_event ('Message', {
						nick     => $nick,
						username => $fullNick,
						level    => $level,
						address  => $addr,
						message  => $text,
					});
				}
			}
			elsif ($command == 35) {
				# 35 = Who List Update.

				# Keep track of all the FullNick's we found.
				my %this = ();

				# Keep running arrays of users for the WhoList event.
				my @list = ();

				# Go through each item received.
				foreach my $user (@args) {
					my ($nick,$addr) = split(/\,/, $user, 2);
					my $fullNick = $nick;

					# Get data about this user.
					my ($level) = $nick =~ /^(\d)/;
					$nick =~ s/^(\d)//i;

					# User is online.
					if ($level == 0) {
						# Add user to the normal users list.
						$self->{who}->{$nick} = $addr;
						$self->{nicks}->{who}->{$nick} = $fullNick;
					}
					else {
						# Add them to the Cyan & Guests list.
						$self->{special}->{$nick} = $addr;
						$self->{nicks}->{special}->{$nick} = $fullNick;
					}

					push (@list, {
						nick     => $nick,
						level    => $level,
						address  => $addr,
						username => $fullNick,
					});
					$this{$fullNick} = 1;
				}

				# New event: WhoList = sends the entire Who List at once.
				$self->_event ('WhoList', @list);

				# See if anybody should be dropped.
				foreach my $who (keys %{$self->{who}}) {
					my $fullNick = $self->{nicks}->{who}->{$who};
					if (!exists $this{$fullNick}) {
						# Buddy's gone.
						delete $self->{who}->{$who};
					}
				}
				foreach my $who (keys %{$self->{special}}) {
					my $fullNick = $self->{nicks}->{special}->{$who};
					if (!exists $this{$fullNick}) {
						# Buddy's gone.
						delete $self->{special}->{$who};
					}
				}

				# If we haven't been connected, now is the time to authenticate.
				if ($self->{connected} == 0) {
					$self->{connected} = 1;

					# Send event 40 to the server (40 = client ready).
					$self->send ("40|$self->{proto}");

					# The server is ready for us now.
					$self->_event ('Connected');

					# Start the pinging process.
					$self->{pinged} = time();
				}
			}
			elsif ($command == 40) {
				# 40 = Server welcome message (the "pong" of 40 from the client).
				$args[0] =~ s/^1//i;
				$self->_event ('Welcome', $args[0]);
			}
			elsif ($command == 70) {
				# 70 = Ignored/Unignored a user.
				my $user = $args[0];
				$self->_event ('Ignored', $user);
			}
			else {
				$self->debug ("Unknown event code from server: $command|"
					. join ('|', @args) );
			}
		}
	}

	return 1;
}

1;
__END__

=head1 NAME

Net::CyanChat - Perl interface for connecting to Cyan Worlds' chat room.

=head1 SYNOPSIS

  use Net::CyanChat;

  my $cyan = new Net::CyanChat (
        host    => 'cho.cyan.com', # default
        port    => 1812,           # main port--1813 is for testing
        proto   => 1,              # use protocol 1.0
        refresh => 60,             # ping rate (default)
  );

  # Set up handlers.
  $cyan->setHandler (foo => \&bar);

  # Connect
  $cyan->start();

=head1 DESCRIPTION

Net::CyanChat is a Perl module for object-oriented connections to Cyan Worlds, Inc.'s
chat room.

=head1 NOTE TO DEVELOPERS

CyanChat regulars aren't fond of having chat bots in their room. The following
guidelines should be followed when connecting to C<cho.cyan.com> (the official
CyanChat server):

  1. Don't create a bot that sends messages publicly to the chat room.
  2. CyanChat regulars don't like logging bots either (ones that would i.e. allow
     users to read chat transcripts online without having to participate in the
     chat room themselves).
  3. Don't do auto-shorah (or, automatically greeting members as they enter the
     chat room).

C<Net::CyanChat> was created to aid in a Perl CyanChat client program. This is
how it should stay. Use this module to program an interactive chat client, not
a bot.

=head1 VOCABULARY

For the sake of this manpage, the following vocabulary will be used:

  nick (or nickname):
    This is the displayed name of the user, as would be seen in the Who List
    and in messages they send.

  username (or fullname):
    This is the name that CyanChat refers to users internally by. It's the same
    as the nickname but it has a number in front. See "CyanChat Auth Levels"
    below for the meaning of the numbers.

=head1 METHODS

=head2 new (ARGUMENTS)

Constructor for a new CyanChat object. Pass in any arguments you need. Some standard arguments
are:

  host:    The hostname or IP of a CyanChat server.
           Default: cho.cyan.com
  port:    The port number that a CyanChat server is listening on.
           Default: 1812
           Note:    Port 1812 on cho.cyan.com is the standard official CyanChat
                    service. This server is very strict about the protocol. Sending
                    malformed packets will get you banned from the server.
           Note:    Port 1813 on cho.cyan.com is the development server. The server
                    is less strict about poorly formatted commands and won't ban your
                    IP when such happens. There still is a profanity filter though.
  proto:   The number of the CyanChat protocol to use (between versions 0 and 1).
           Default: 1
           Note:    See the CyanChat Developers link below for specifications of
                    the protocol versions.
  debug:   Debug mode. When active, client/server packets are displayed in your
           terminal window (or whereever STDOUT directs to).
  refresh: The "ping rate". The CyanChat server sometimes disconnects clients who
           are idle for long periods of time. There is no "ping" system implemented
           in the protocol. Many CC clients "ping" by sending an empty private
           message to an empty nickname. The refresh rate here determines how many
           seconds it waits between doing this.
           Default: 60

Returns a C<Net::CyanChat> object. See L<"CHO"> for tips about the official
CyanChat server.

=head2 version

Returns the version number of the module.

=head2 debug (MESSAGE)

Called by the module itself for debug messages.

=head2 send (DATA)

Send raw data to the CyanChat server. This method is dangerous to be used
manually, as the official server doesn't tolerate malformed packets.
See L<"CHO"> for details.

=head2 setHandler (EVENT_CODE => CODEREF)

Set up a handler for the CyanChat connection. See below for a list of handlers.

=head2 connect

Connect to the CyanChat server. Will return undef and call your C<Error>
handler if the connection fails; otherwise returns 1.

=head2 start

Start a loop of do_one_loop's. Will break and return undef when a do_one_loop
fails.

=head2 do_one_loop

Perform a single loop on the server. Returns undef on error; 1 otherwise.

=head2 login (NICK)

After receiving a "Connected" event from the server, it is okay to log in now. NICK
should be no more than 20 characters and cannot contain a pipe symbol "|" or
a comma.

Of interest, it seems that on L<"CHO"> you can call the login method more than
once. Effectually you send another "has logged in" event under the new nick,
without having sent a "has left" event. The server wasn't intended to behave this
way, so your mileage may vary.

=head2 logout

Log out of CyanChat if you're currently logged in. B<Never> call this method
if your object is not currently logged in. L<"CHO"> will consider it a bad
packet and ban your IP.

=head2 sendMessage (MESSAGE)

Broadcast a message publicly to the chat room. You must have logged in to the
chat room before you can call this method.

=head2 sendPrivate (USERNAME, MESSAGE)

Send a private message to recipient USERNAME. You must be logged in first.

=head2 getBuddies

Returns a hashref containing "who" (normal users) and "special" (Cyan & Guests).
Under each key are keys containing the Nicknames and their Addresses as values.
Example:

  {
    who => {
      'Kirsle' => '11923769',
    },
    special => {},
  };

=head2 getUsername (NICK)

Returns the full username of passed in NICK. If NICK is not in the room, returns undef.
This function was historically named C<getFullName>. The old function is an alias to
the new one.

=head2 getAddress (NICK)

Returns the address to NICK. This is not their IP address; CyanChat encrypts their IP into this
address, and it is basicly a unique identifier for a connection. Multiple users logged on from the
same IP address will have the same chat address. Ignoring users will ignore them by address.

=head2 protocol

Returns the protocol version you are using. Will return 0 or 1.

=head2 ignore (USER), unignore (USER)

Ignore and unignore a username. This sends the "Ignore" event to the server as
well as keeping track internally that the user is ignored. Unignoring a user
probably doesn't work, so if your client needs to support this you should handle
it "manually" (ex. not display messages from this user if they're ignored but
don't actually ignore them through the CC protocol).

=head2 nick

Returns the currently signed in nickname of the CyanChat object, or the blank
string if not logged in.

=head1 ADVANCED METHODS

B<WARNING:> These methods are very dangerous to use if you don't know what you're doing.
Don't call authenticate() unless you know for sure what the CyanChat admin password is,
and don't call promote() or demote() unless you are already authenticated as a CyanChat
staff user.

Calling the authenticate() command with the wrong password will most likely get you
banned from CyanChat, and calling promote() or demote() without being an admin user
will probably have the same effect.

In other words, B<don't use these methods unless you know what you're doing!>
See L<"CHO"> for more information.

B<Note that these commands aren't official.> The section of the CyanChat protocol
dealing with administrative functionality isn't public knowledge. Instead, some
functionality has been guessed upon based on the gaps in the protocol specification.

The following functionality B<does> work when the chat server is running on the
Net::CyanChat::Server module, but it may not work with other implementations
of a CyanChat server, and it will most likely not work with L<"CHO">.

=head2 authenticate (PASSWORD)

Authenticate your connection as a Cyan Worlds staff member. Call this method before
entering the chat room. If approved by the server, you will log in with an
administrative (cyan-colored) nickname.

=head2 promote (USER)

Promote USER to a Special Guest. Special guests are typically rendered in orange
text and appear in a special "Cyan & Guests" who list.

=head2 demote (USER)

Demote USER to a normal user level.

=head1 HANDLERS

Handlers are implemented via the C<setHandler> function. Here is an example
handler:

  $cc->setHandler (Welcome => \&on_welcome);

  sub on_welcome {
    my ($cyanchat, $message) = @_;
    print "[ChatServer] $message\n";
  }

The handlers are listed here in the format of "HandlerName (Parameters)". All
handlers receive a copy of the C<Net::CyanChat> object and then any additional
parameters based on the nature of the event.

=head2 Connected (CYANCHAT)

Called when a connection has been established, and the server recognizes your client's
presence. At this point, you can call CYANCHAT->login (NICK) to log into the chat room.

=head2 Disconnected (CYANCHAT)

Called when a disconnect has been detected.

=head2 Welcome (CYANCHAT, $MESSAGE)

Called after the server recognizes your client (almost simultaneously to Connected).
MESSAGE are messages that the CyanChat server sends--mostly just includes a list of the
chat room's rules.

Note that CyanChat is different to most traditional chat rooms: new messages are
displayed on the top of your chat history. The Welcome handler is called for each
message, and these messages will arrive in reverse order to what you'd expect,
since the new messages should be displayed above the previous ones. When all the
welcome messages arrive, then it can be read from top to bottom normally.

=head2 Message (CYANCHAT, \%INFO)

Called when a user sends a message publicly in chat. INFO is a hash reference
containing the following keys:

  nick:     The user's nickname.
  username: Their full username.
  address:  Their encoded IP address.
  level:    Their auth level (see "CyanChat Auth Levels" below).
  message:  The text of their message.

Example:

  $cc->setHandler (Message => sub {
    my ($cyan,$info) = @_;
    print "[$info->{nick}] $info->{message}\n";
  });

All of the following handlers have the same structure for their "INFO" parameter.

=head2 Private (CYANCHAT, \%INFO)

Called when a user sends a private message to your client.

=head2 Ignored (CYANCHAT, $USER)

Called when a username has ignored us in chat. This is used in the standard chat
client so that you can perform a mutual ignore (your client automatically ignores
the remote user when they ignore you). The idea is that if a user is being abusive
in chat and everybody in the room ignores them, it will appear to them as though
everybody has left (because their client will have ignored everyone else too).

=head2 Chat_Buddy_In (CYANCHAT, \%INFO)

Called when a buddy enters the chat room. NICK, USERNAME, LEVEL, and ADDRESS are the same as in the
Message and Private handlers. MESSAGE is their join message (i.e. "<links in from comcast.net age>")

=head2 Chat_Buddy_Out (CYANCHAT, \%INFO)

Called when a buddy exits. MESSAGE is their exit message (i.e. "<links safely back to their home Age>"
for normal log out, or "<mistakenly used an unsafe Linking Book without a maintainer's suit>" for
disconnected).

=head2 WhoList (CYANCHAT, @USERS)

This handler is called whenever a "35" (WhoList) event is received from the server. USERS is an array
of hashes containing information about all the users in the order they were received from the server.

Each item in the array is a hash reference with the following keys:

  nick:     Their nickname (ex: Kirsle)
  username: Their username (ex: 0Kirsle)
  address:  Their chat address
  level:    Their auth level (ex: 0)

=head2 Name_Accepted (CYANCHAT)

The CyanChat server has accepted your name.

=head2 Error (CYANCHAT, $CODE, $STRING)

Handles errors issued by CyanChat. CODE is the exact server code issued that caused the error.
STRING is either an English description or the exact text the server sent.

Potential errors that would come up:

  00 Connection error
  10 Your name is invalid

=head1 CYAN CHAT RULES

The CyanChat server strictly enforces these rules:

  Be respectful and sensitive to others (please, no platform wars).
  Keep it "G" rated (family viewing), both in language and content.
  And HAVE FUN!

  Termination of use can happen without warning!

See L<"CHO"> for what exactly "Termination of use can happen without warning!" means.

=head1 CYAN CHAT AUTH LEVELS

Auth levels (received as LEVEL to most handlers, or prefixed onto a user's FullName) are as follows:

  0 is for regular chat user (should be in white)
  1 is for Cyan Worlds employee (should be in cyan)
  2 is for CyanChat Server message (should be in lime green)
  4 is for special guest (should be in gold or orange)
  Any other number is probably a client error message (should be in red)

=head1 CHO

This section of the manpage provides some tips for interacting with the standard
official CyanChat server, C<cho.cyan.com>.

B<Cho is picky about the protocol.> If you send a malformed packet to Cho, it
will most likely ban your IP address. Usually the first offense results in a
24 hour ban. Repeat offenses last longer and longer (possibly indefinitely).

B<Cho has a bad language filter.> Sending a severe swear word results in an
instant, permanent ban. Less severe swear words result in a 24 hour ban, or a
longer ban if it's a repeat offense.

B<Cho has a development server.> C<cho.cyan.com> port C<1813> is the development
server. The server here is tolerant of packet mistakes and will warn you about
them instead of banning your client. However, the bad language filter still
exists here.

=head1 CHANGE LOG

  Version 0.07 - Sep 18 2015
  - Update documentation.

  Version 0.06 - Oct 24 2008
  - Broke backwards compatibility *big time*.
  - Removed the Chat_Buddy_Here method. It was useless and difficult to work with.
  - All the Message handlers (Message, Private, Chat_Buddy_In, Chat_Buddy_Out)
    now receive a hashref containing the details of the event, instead of
    receiving them in array format.
  - The Who Lists are now separated internally into "Who" (normal users)
    and "Special" (Cyan & Guests). Cyanites so rarely enter the CyanChat room
    that conflicts in nicknames between normal users and Cyanites was rare, but
    possible, and the previous version of the module wouldn't be able to handle
    that.
  - The function getBuddies returns a higher level hash dividing the users into
    the "who" and "special" categories (i.e. $ret->{who}->{Kirsle} = 11223135).
  - All functions return undef on error now, and 1 on success (unless another
    value is expected), instead of returning 0 on error.
  - Removed some leftover prints in the code from the last version.
  - Revised the POD to include some bits of example code, particularly around
    the HANDLERS section.
  - Added a new section to the POD to list some tips for interacting with the
    official chat server, Cho.
  - Cleared up some of the vocabulary in the POD, since "nicknames" and
    "usernames" are two different beasts, and it's important to know which one
    to use for any given method.
  - Included a command-line CyanChat client as a demonstration of this module
    (and to complement the `ccserver` script). The client requires Term::ReadKey
    and, on Win32, Win32::Console::ANSI (if you want ANSI colors).

  Version 0.05 - Jun  1 2007
  - Fixed the end-of-line characters, it now sends a true CrLf.
  - Added the WhoList handler.
  - Added the authenticate(), promote(), and demote() methods.

  Version 0.04 - Oct 24 2006
  - The enter/exit chat messages now go by the tag number (like it's supposed to),
    not by the contained text.
  - Messages can contain pipes in them and be read okay through the module.
  - Added a "ping" function. Apparently Cho will disconnect clients who don't do
    anything in 5 minutes. The "ping" function also helps detect disconnects!
  - The Disconnected handler has been added to detect disconnects.

  Version 0.03 - Oct  1 2006
  - Bug fix: the $level received to most handlers used to be 1 (cyan staff) even
    though it should've been 0 (or any other number), so this has been fixed.

  Version 0.01 - May 14 2005
  - Initial release.
  - Fully supports both protocols 0 and 1 of CyanChat.

=head1 SEE ALSO

Net::CyanChat::Server

CyanChat Protocol Documentation: http://cho.cyan.com/chat/programmers.html

=head1 AUTHOR

Noah Petherbridge, http://www.kirsle.net/

=head1 COPYRIGHT AND LICENSE

    Net::CyanChat - Perl interface to CyanChat.
    Copyright (C) 2007-2015  Noah Petherbridge

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
