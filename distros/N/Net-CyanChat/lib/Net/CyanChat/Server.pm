package Net::CyanChat::Server;

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
		host       => 'localhost',
		port       => 1812,
		password   => undef, # Staff password for command 50
		sock       => undef,
		select     => undef,
		welcome    => [
			"Welcome to Net::CyanChat::Server v. $VERSION",
			"",
			"There are only a few simple rules:",
			"    1. Be respectful to other users.",
			"    2. Keep the dialog \"G\" rated.",
			"    3. And HAVE FUN!",
			"",
			"Termination of use can happen without warning!",
		],
		conn       => {},
		who        => {},
		@_,
	};

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

sub connect {
	my ($self) = @_;

	# Create the socket.
	$self->{sock} = IO::Socket::INET->new (
		LocalAddr => $self->{host},
		LocalPort => $self->{port},
		Listen    => 1,
		Reuse     => 1,
	) or die "Socket error: $!";

	# Create a select object.
	$self->{select} = IO::Select->new ($self->{sock});
	return 1;
}

sub start {
	my ($self) = @_;
	while (1) {
		$self->do_one_loop();
	}
	return undef;
}

sub reply {
	my ($self,$socket,$msg) = @_;

	# Send the message.
	print "S: $msg\n";
	eval {
		$socket->send ("$msg\x0d\x0a") or do {
			# He's been disconnected.
			my $id = $socket->fileno;
			if ($self->{conn}->{$id}->{login}) {
				# Remove him.
				my $user = $self->{conn}->{$id}->{username};
				delete $self->{who}->{$user};
				delete $self->{conn}->{$id};

				# Broadcast it.
				$self->broadcast ("31|$user|^3<mistakenly used an unsafe Linking Book without a maintainer's suit *ZZZZZWHAP*>");
				$self->sendWhoList();
			}

			$self->{select}->remove ($socket);
			$socket->close();
		}
	};

	if ($@) {
		warn "<$@>";
		$self->{select}->remove ($socket);
	}
}

sub do_one_loop {
	my ($self) = @_;

	# Look for events.
	my @ready = $self->{select}->can_read(.1);
	return unless(@ready);

	# Go through each event.
	foreach my $socket (@ready) {
		# If the listening socket is ready, accept a new connection.
		if ($socket == $self->{sock}) {
			my $new = $self->{sock}->accept();
			$self->{select}->add ($new);
			print $new->fileno . ": connected\n";

			# Setup data for this connection.
			my $nid = $new->fileno;
			$self->{conn}->{$nid} = {
				level    => 0,
				announce => 0,
				nickname => undef,
				username => undef,
				login    => 0,
			};

			# Send a 35.
			my @memlist = ();
			foreach my $member (keys %{$self->{who}}) {
				my $addr = $self->{who}->{$member};
				push (@memlist,"$member,$addr");
			}
			my $mems = join ('|', @memlist);
			$self->reply ($new,"35|$mems");
		}
		else {
			# Get their ID.
			my $id = $socket->fileno;

			# Read their request.
			my $line = '';
			$socket->recv ($line, 2048);
			chomp $line;
			$line =~ s/\r//ig;
			$line =~ s/\n//ig;

			# Skip if this line is blank.
			next if $line eq "";

			# Go through the events.
			my ($cmd,@args) = split(/\|/, $line);

			print "C $id: $line\n";

			if ($cmd == 10) {
				# 10 = Sending their name.
				if ($self->{conn}->{$id}->{announce}) {
					my $nick = join ("|",@args);
					if (!defined $nick) {
						# No nick defined.
						$self->reply ($socket,"21|3ChatServer|^1No nickname was defined!");
					}
					else {
						# Format their username.
						my $user = join ("", $self->{conn}->{$id}->{level}, $nick);

						# Valid nick?
						if (length $nick <= 20 && $nick !~ /\|/) {
							# See if the nick isn't already logged on.
							if (exists $self->{who}->{$user}) {
								$self->reply ($socket,"21|3ChatServer|^1The nickname is already in use.");
							}
							else {
								# Setting another name?
								if (length $self->{conn}->{$id}->{username} > 0) {
									# Remove the old.
									my $old = $self->{conn}->{$id}->{username};
									delete $self->{who}->{$old};
								}

								# Make up their join message.
								my $join = "somewhere on the internet Age";

								# Staff?
								if ($self->{conn}->{$id}->{level} == 1) {
									$join = "Cyan Worlds, Inc.";
								}

								# Join them.
								$self->{who}->{$user} = $socket->peerhost;
								$self->{conn}->{$id}->{username} = $user;
								$self->{conn}->{$id}->{nickname} = $nick;
								$self->{conn}->{$id}->{login} = 1;
								$self->reply ($socket,"11"); # 11 = name accepted
								$self->broadcast ("31|$user|^2<links in from $join>");

								# Update the Who List.
								$self->sendWhoList();
							}
						}
						else {
							# Invalid nick.
							$self->reply ($socket,"10"); # 10 = name invalid
						}
					}
				}
			}
			elsif ($cmd == 15) {
				# 15 = Remove their name (sign out).
				if ($self->{conn}->{$id}->{login}) {
					# Exit them.
					my $nick = $self->{conn}->{$id}->{username};
					$self->{conn}->{$id}->{username} = undef;
					$self->{conn}->{$id}->{nickname} = undef;
					$self->{conn}->{$id}->{login} = 0;
					delete $self->{who}->{$nick};
					$self->broadcast ("31|$nick|^3<links safely back to their home Age>");
					$self->sendWhoList();
				}
			}
			elsif ($cmd == 20) {
				# 20 = send private message.
				if ($self->{conn}->{$id}->{login}) {
					my $to = shift @args;
					my $msg = join ("|",@args);

					if ($to && $msg) {
						# Send to this user's socket.
						my $recipient = $self->getSocket ($to);
						$self->reply ($recipient,"21|$to|$msg");
					}
				}
			}
			elsif ($cmd == 30) {
				# 30 = send public message.
				if ($self->{conn}->{$id}->{login}) {
					my $msg = join ("|",@args);
					$self->broadcast ("31|$self->{conn}->{$id}->{username}|$msg");
				}
			}
			elsif ($cmd == 40) {
				# 40 = client ready.
				my $proto = join ("|",@args);
				$proto = 0 unless length $proto > 0;

				# Client is ready now.
				$self->{conn}->{$id}->{announce} = 1;
				my @welcome = reverse (@{$self->{welcome}});
				foreach my $send (@welcome) {
					$self->reply ($socket,"40|1$send");
				}
			}
			elsif ($cmd == 50) {
				# 50 = Staff password.
				my $pass = join ("|",@args);

				if (defined $self->{password} && $pass eq $self->{password}) {
					# This is a staff member.
					print "Make $id a Staff Connection\n";
					$self->{conn}->{$id}->{level} = 1;
				}
			}
			elsif ($cmd == 60) {
				# 60 = Promote other users
				my ($user,$newlevel) = @args;

				# Only admin users can use this option.
				if ($self->{conn}->{$id}->{level} == 1) {
					# See that the user they mentioned exists.
					my $targetid = -1;
					my $oldwho = '';
					foreach my $con (keys %{$self->{conn}}) {
						next unless exists $self->{conn}->{$con}->{nickname};
						if ($self->{conn}->{$con}->{nickname} eq $user) {
							$oldwho = $self->{conn}->{$con}->{username};
							$targetid = $con;
						}
					}

					if ($targetid >= 0) {
						# They do. Promote them.
						my $newwho = join ("",$newlevel,$user);
						$self->{conn}->{$targetid}->{level} = $newlevel;
						$self->{conn}->{$targetid}->{username} = $newwho;
						$self->{who}->{$newwho} = delete $self->{who}->{$oldwho};
						print "Promote $user ($targetid) to $newlevel\n";
						use Data::Dumper;
						print Dumper($self);

						# Send the Who List.
						$self->sendWhoList();
					}
					else {
						$self->reply ($socket,"21|3ChatClient|^1User not found.");
					}
				}
				else {
					$self->reply ($socket,"21|3ChatClient|^Permission denied.");
				}
			}
			elsif ($cmd == 70) {
				# 70 = ignore user
				my $target = join ("|",@args);
				if (length $target > 0) {
					# Send mutual ignore to this user's client.
					my $recipient = $self->getSocket ($target);
					$self->reply ($recipient,"70|$self->{conn}->{$id}->{username}");
				}
			}
			else {
				# Unknown command.
				if ($self->{conn}->{$id}->{login}) {
					$self->reply ($socket,"21|3ChatClient|^1Command not implemented.");
				}
			}
		}
	}
}

sub setWelcome {
	my ($self,@msgs) = @_;

	# Keep these messages.
	return unless @msgs;

	$self->{welcome} = [ @msgs ];

	return 1;
}

sub setPassword {
	my ($self,$pass) = @_;

	# Save the password.
	if (defined $pass) {
		if (length $pass > 0) {
			$self->{password} = $pass;
		}
		else {
			$self->{password} = undef;
		}
	}

	return $self->{password};
}

sub url {
	my ($self) = @_;

	return join (':', $self->{host}, $self->{port});
}

sub sendWhoList {
	my ($self) = @_;

	# Get the Who List.
	my @memlist = ();
	foreach my $member (keys %{$self->{who}}) {
		my $addr = $self->{who}->{$member};
		push (@memlist,"$member,$addr");
	}
	my $list = join ('|', @memlist);

	# Send the Who List to all connections.
	foreach my $socket ($self->{select}->handles) {
		next if ($socket == $self->{sock});

		# Send the 35.
		$self->reply ($socket,"35|$list");
	}

	return 1;
}

sub getSocket {
	my ($self,$handle) = @_;

	# Find this handle's socket.
	foreach my $socket ($self->{select}->handles) {
		my $id = $socket->fileno;
		if (exists $self->{conn}->{$id}->{username}) {
			if ($handle eq $self->{conn}->{$id}->{username}) {
				return $socket;
			}
		}
	}

	return undef;
}

sub broadcast {
	my ($self,$data) = @_;

	# Find this handle's socket.
	foreach my $socket ($self->{select}->handles) {
		my $id = $socket->fileno;
		if ($self->{conn}->{$id}->{login}) {
			# Send it.
			$self->reply ($socket,$data);
		}
	}
}

1;
__END__

=head1 NAME

Net::CyanChat::Server - Perl interface for running a CyanChat server.

=head1 SYNOPSIS

  use Net::CyanChat::Server;

  our $cho = new Net::CyanChat::Server (
          host  => 'localhost',
          port  => 1812,
          debug => 1,
  );

  # Start the server.
  $cho->connect();

  # Loop.
  $cho->start();

=head1 DESCRIPTION

Net::CyanChat::Server is a Perl interface for running your own CyanChat server (or, rather,
to run a chat server based on the CyanChat protocol that other CC clients would recognize).

=head1 METHODS

=head2 new (ARGUMENTS)

Constructor for a new CyanChat server. Pass in the host, port, and debug. All are optional.
host defaults to localhost, port defaults to 1812, debug defaults to 0. With debug on, all
the server/client conversation is printed.

Returns a CyanChat server object.

=head2 version

Returns the version number.

=head2 debug ($MESSAGE)

Called by the module itself for debug messages.

=head2 connect

Open the server socket and listen for connections.

=head2 start

Start a loop of do_one_loop's.

=head2 do_one_loop

Perform a single loop of checking for new connections and events from existing
connections.

=head2 setWelcome (@MESSAGES)

Set the Welcome Messages that are displayed when a user connects to the chat. The default messages are:

  Welcome to Net::CyanChat::Server v. <VERSION>

  There are only a few simple rules:
       1. Be respectful to other users.
       2. Keep the dialog "G" rated.
       3. And HAVE FUN!

  Termination of use can happen without warning!

=head2 setPassword ($PASS)

Define the password that is required to authenticate as a staff member. A
client would use this password by sending the command below before logging in
to the chat room:

  50|password

Note that this part of the protocol support is not official. The administrative
commands in the CyanChat protocol is not public knowledge and so this support
was just speculated on based on the gaps in the protocol documentation. This
probably only works with clients using the Net::CyanChat module.

=head2 url

Returns the host/port to your CyanChat server (i.e. "localhost:1812")

=head2 reply ($SOCKET, $DATA)

Send data to the specified SOCKET object.

=head2 getSocket ($USERNAME)

Get the socket of a username signed into the chat room.

=head2 broadcast ($DATA)

Broadcasts commands to all logged-in users.

=head2 sendWhoList

Sends the Who List to all users. This should be called when a user joins or exits the
room.

=head1 CHANGE LOG

Version 0.03

  - Cleaned up the documentation a bit.

Version 0.02

  - Messages can contain pipes in them now.
  - Removed the "staff protocol" number; replaced it with "staff password"
  - Changed the socket end-of-lines to CrLf instead of just Lf.

Version 0.01

  - Initial release.

=head1 TO DO

  - Add support for built in profanity filters and bans.
  - Add IP encryption algorythm similar to Cyan's.
  - Display user's ISP as their home Age, rather than their IP address.

=head1 SEE ALSO

Net::CyanChat

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
