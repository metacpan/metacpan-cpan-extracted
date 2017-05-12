#!/usr/bin/perl

# A front-end to RiveScript.
# See `rivescript --help` for help.

use 5.10.0;
use strict;
use warnings;
use RiveScript;
use Getopt::Long;
use Pod::Text;
use IO::Socket;
use IO::Select;
use JSON;

#------------------------------------------------------------------------------#
# Command Line Arguments                                                       #
#------------------------------------------------------------------------------#

my $opt = {
	debug   => 0,  # --debug, enables debug mode
	verbose => 1,  # Private, verbose mode for RS
	log     => "", # --log, debug logs to file instead of terminal
	json    => 0,  # --json, running in batch mode
	listen  => "", # --listen, listen on a TCP port
	utf8    => 0,  # --utf8, use UTF-8 mode in RiveScript
	depth   => 50, # depth variable
	strict  => 1,  # --strict, strict mode
	data    => "", # --data, provide JSON data via CLI instead of STDIN
	help    => 0,  # --help
};
GetOptions (
	'debug|d'    => \$opt->{debug},
	'log=s'      => \$opt->{log},
	'help|h|?'   => \$opt->{help},
	'json|j'     => \$opt->{json},
	'utf8|u'     => \$opt->{utf8},
	'listen|l=s' => \$opt->{listen},
	'depth=i'    => \$opt->{depth},
	'data=s'     => \$opt->{data},
	'strict!'    => \$opt->{strict},
);

# Asking for help?
if ($opt->{help}) {
	# Give them our POD instructions.
	my $pod = Pod::Text->new (sentence => 0, width => 78);
	$pod->parse_from_filehandle(*DATA);
	exit(0);
}

# Debug mode options.
if ($opt->{log}) {
	# Logging automatically enables debugging.
	$opt->{debug}   = 1;
	$opt->{verbose} = 0;
}

# UTF-8 support?
if ($opt->{utf8}) {
	binmode(STDIN, ":utf8");
	binmode(STDOUT, ":utf8");
	binmode(STDERR, ":utf8");
}

#------------------------------------------------------------------------------#
# Main Program Begins Here                                                     #
#------------------------------------------------------------------------------#

# A brain has been specified?
my $root = scalar(@ARGV) ? $ARGV[0] : $RiveScript::basedir . "/demo";

# Create the RiveScript interpreter.
my $rs = init();
my $json;   # JSON interpreter if we need it.
my $server; # Server socket if we need it.
my $select; # Selector object if we need it.

# Interactive mode?
if (!$opt->{json} && !$opt->{listen}) {
	# If called with no arguments, hint about the --help option.
	unless (scalar(@ARGV)) {
		print "Hint: use `rivescript --help` for documentation on this command.\n\n";
	}

	print "RiveScript Interpreter - Interactive Mode\n"
		. "-----------------------------------------\n"
		. "RiveScript Version: $RiveScript::VERSION\n"
		. "        Reply Root: $root\n\n"
		. "You are now chatting with the RiveScript bot. Type a message and press Return to send it.\n"
		. "When finished, type '/quit' to exit the program. Type '/help' for other options.\n\n";

	while (1) {
		print "You> ";
		chomp(my $input = <STDIN>);

		# Commands.
		if ($input =~ /^\/help/i) {
			print "> Supported Commands:\n"
				. "> /help   - Displays this message.\n"
				. "> /reload - Reload the RiveScript brain.\n"
				. "> /quit   - Exit the program.\n";
		}
		elsif ($input =~ /^\/reload/i) {
			# Reload the brain.
			undef $rs;
			$rs = init();
			print "> RiveScript has been reloaded.\n\n";
		}
		elsif ($input =~ /^\/(?:quit|exit)/i) {
			# Quit.
			exit(0);
		}
		else {
			# Get a response.
			my $reply = $rs->reply("localuser", $input);
			print "Bot> $reply\n";
		}
	}
}
else {
	# JSON mode.
	$json = JSON->new->pretty();

	# Are we listening from a TCP socket or standard I/O?
	if ($opt->{listen}) {
		tcp_mode();
	} else {
		json_mode();
	}
}

# Handle JSON mode: standard input and output
sub json_mode {
	my $buffer   = "";
	my $stateful = 0;

	# Did they provide us a complete message via --data?
	if ($opt->{data}) {
		$buffer = $opt->{data};
	} else {
		# Nope. Read from standard input. This loop breaks when we
		# receive the EOF (Ctrl+D) signal.
		while (my $line = <STDIN>) {
			chomp($line);
			$line =~ s/[\x0D\x0A]+//g;

			# Look for the __END__ line.
			if ($line =~ /^__END__$/i) {
				# Process it.
				$stateful = 1; # This is a stateful session.
				print json_in($buffer, 1);
				$buffer = "";
				next;
			}

			$buffer .= "$line\n";
		}
	}

	# If the session was stateful, just exit, otherwise
	# process what we just read.
	if ($stateful) {
		exit(0);
	}

	print json_in($buffer);
	exit(0);
}

# Handle TCP mode: using a TCP socket
sub tcp_mode {
	# Validate the listen parameter.
	my $hostname = "localhost";
	my $port     = 2001;
	if ($opt->{listen} =~ /^(.+?):(\d+)$/) {
		$hostname = $1;
		$port     = $2;
	} elsif ($opt->{listen} =~ /^\d+$/) {
		$port     = $opt->{listen};
	} else {
		print "The --listen option requires an address and/or port number. Examples:\n"
			. "--listen localhost:2001\n"
			. "--listen 2001\n";
		exit(1);
	}

	# Create a listening socket.
	$server = IO::Socket::INET->new (
		LocalAddr => $hostname,
		LocalPort => $port,
		Proto     => 'tcp',
		Listen    => 1,
		Reuse     => 1,
	);
	if (!$server) {
		say "Couldn't create socket on $hostname:$port: $@";
		exit 1;
	}

	# Create a socket selector.
	$select = IO::Select->new($server);

	say "Listening for connections at $hostname:$port";

	# Listen for events.
	while (do_one_loop()) {
		select(undef,undef,undef,0.001);
	}
}

# Main loop for TCP server.
my $buffer = {}; # Message buffers per connection.
sub do_one_loop {
	# Look for new events.
	my @ready = $select->can_read(.1);
	return 1 unless @ready;

	foreach my $socket (@ready) {
		my $id = $socket->fileno;
		if ($socket == $server) {
			# It's a new connection.
			$socket = $server->accept();
			$select->add($socket);
			$id = $socket->fileno; # Get the correct fileno for the new socket.
			say ts() ."Connection created: $id";

			# Initialize their buffers.
			$buffer->{$id} = {
				buffer => "", # Current line being read
				lines  => [], # Previous lines being read
			};
		} else {
			# Read what they have to say.
			my $buf;
			$socket->recv($buf, 1024);

			# Completely empty? They've disconnected.
			if (length $buf == 0) {
				# Note that even a "blank line" will still have \r\n characters, so there are
				# no false positives to be had here!
				disconnect($socket);
				next;
			}

			# Trim excess fat.
			$buf =~ s/\x0D\x0A/\x0A/g; # The \r characters

			# Any newlines here?
			if ($buf =~ /\n/) {
				my @pieces = split(/\n/, $buf);
				if (scalar(@pieces) > 1) {
					$buffer->{$id}->{buffer} = pop(@pieces);    # Keep the most recent piece

					# Is this the end?
					if ($buffer->{$id}->{buffer} =~ /^__END__/) {
						# We want this piece after all!
						push(@pieces, $buffer->{$id}->{buffer});
						$buffer->{$id}->{buffer} = "";
					}
				}
				push (@{$buffer->{$id}->{lines}}, @pieces); # Stash the rest
			}

			# Are they done?
			if (scalar @{$buffer->{$id}->{lines}} > 0 &&
			$buffer->{$id}->{lines}->[-1] eq "__END__") {
				# Get their response.
				my @lines = @{$buffer->{$id}->{lines}};
				pop(@lines); # Remove the __END__ line.

				# Get the reply and send it.
				my $response = json_in(join("\n",@lines), 1, $id);
				sock_send($socket, $response);

				# Reset their line buffer.
				$buffer->{$id}->{lines} = [];
			} elsif (scalar @{$buffer->{$id}->{lines}} > 20 || length($buffer->{$id}->{buffer}) > 1024) {
				# This is getting ridiculous.
				sock_send($socket, $json->encode({
					status => "error",
					reply => "Internal Error: Input stream too long. Giving up.",
				}), 1);
				next;
			}
		}
	}

	return 1;
}

# Send a message to a socket.
sub sock_send {
	my ($socket,$msg,$disconnect_after) = @_;

	$socket->send($msg) or do {
		# They've been disconnected.
		disconnect($socket);
		return;
	};

	# Disconnect after?
	if ($disconnect_after) {
		disconnect($socket);
	}
}

# Disconnect a socket.
sub disconnect {
	my $socket = shift;
	my $id     = $socket->fileno;
	say ts() . "Disconnected: $id";

	# Forget we ever saw them.
	delete $buffer->{$id};
	$select->remove($socket);
	$socket->close();
}

# Initializes the RiveScript interpreter.
sub init {
	my $rs = RiveScript->new (
		debug     => $opt->{debug},
		verbose   => $opt->{verbose},
		debugfile => $opt->{log},
		depth     => $opt->{depth},
		strict    => $opt->{strict},
		utf8      => $opt->{utf8},
	);

	$rs->loadDirectory($root);
	$rs->sortReplies();
	return $rs;
}

sub json_in {
	my $buffer = shift;
	my $end    = shift;
	my $tcp    = shift;

	my $data  = {};
	my $reply = {
		status => "ok",
	};

	# Try to decode their input.
	eval {
		$data = $json->decode($buffer);
	};

	# Error?
	if ($@) {
		$reply->{status} = "error";
		$reply->{reply}  = "Failed to decode your input: $@";
		if ($tcp) {
			say ts() . "$tcp: Failed to decode JSON input: $@";
		}
	}
	else {
		# Decode their variables.
		my $username = exists $data->{username} ? $data->{username} : "localuser";
		if (ref($data->{vars}) eq "HASH") {
			foreach my $key (keys %{$data->{vars}}) {
				next if ref($data->{vars}->{$key});
				$rs->setUservar($username, $key, $data->{vars}->{$key});
			}
		}

		# Get their answer.
		$reply->{reply} = $rs->reply($username, $data->{message});
		if ($tcp) {
			say ts() . "$tcp: [$username] $data->{message}";
			say ts() . "$tcp: [Response] $reply->{reply}";
		}

		# Retrieve vars.
		$reply->{vars} = {};
		my $vars = $rs->getUservars($username);
		foreach my $key (keys %{$vars}) {
			next if ref($vars->{$key});
			$reply->{vars}->{$key} = $vars->{$key};
		}
	}

	# Encode and print.
	my $return = $json->encode($reply);
	$return .= "__END__\n" if $end;
	return $return;
}

# Simple time stamp.
sub ts {
	my @now = localtime();
	return sprintf("[%02d:%02d:%02d] ", $now[2], $now[1], $now[0]);
}

__DATA__

=head1 NAME

rivescript - A command line frontend to the Perl RiveScript interpreter.

=head1 SYNOPSIS

  $ rivescript [options] [path to RiveScript documents]

=head1 DESCRIPTION

This is a command line front-end to the RiveScript interpreter. This script
obsoletes the old C<rsdemo>, and can also be used non-interactively by third
party programs. To that end, it supports a variety of input/output and session
handling methods.

If no RiveScript document path is given, it will default to the example brain
that ships with the RiveScript module, which is based on the Eliza bot.

=head1 OPTIONS

=over 4

=item --debug, -d

Enables debug mode. This will print all debug data from RiveScript to your
terminal. If you'd like it to log to a file instead, use the C<--log> option
instead of C<--debug>.

=item --log FILE

Enables debug mode and prints the debug output to C<FILE> instead of to your
terminal.

=item --json, -j

Runs C<rivescript> in JSON mode, for running the script in a non-interactive
way (for example, to use RiveScript in a programming language that doesn't have
a native RiveScript library). See L<"JSON Mode"> for details.

=item --data JSON_DATA

When using the C<--json> option, you can provide the JSON input message as a
command line argument with the C<--data> option. If not provided, then the
JSON data will be read from standard input instead. This option is helpful,
therefore, if you don't want to open a two-way pipe, but rather pass the message
as a command line argument and just read the response from standard output.
See L<"JSON Mode"> for more details.

=item --listen, -l [ADDRESS:]PORT

Runs C<rivescript> in TCP mode, for running the script as a server daemon.
If an address isn't specified, it will bind to C<localhost>. See
L<"TCP Mode"> for details.

=item --strict, --nostrict

Enables strict mode for the RiveScript parser. It's enabled by default, use
C<--nostrict> to disable it. Strict mode prevents the parser from continuing
when it finds a syntax error in the RiveScript documents.

=item --depth=50

Override the default recursion depth limit. This controls how many times
RiveScript will recursively follow redirects to other replies. The default is
C<50>.

=item --utf8, -u

Use the UTF-8 option in RiveScript. This allows triggers to contain foreign
characters and relaxes the filtering of user messages. This is not enabled
by default!

=item --help

Displays this documentation in your terminal.

=back

=head1 USAGE

=head2 Interactive Mode

This is the default mode used when you run C<rivescript> without specifying
another mode. This mode behaves similarly to the old C<rsdemo> script and lets
you chat one-on-one with your RiveScript bot.

This mode can be used to test your RiveScript bot. Example:

  $ rivescript /path/to/rs/files

=head2 JSON Mode

This mode should be used when calling from a third party program. In this mode,
data that enters and leaves the script are encoded in JSON.

Example:

  $ rivescript --json /path/to/rs/files

The format for incoming JSON data is as follows:

  {
    "username": "localuser",
    "message":  "Hello bot!",
    "vars": {
      "name": "Aiden"
    }
  }

Here, C<username> is a unique name for the user, C<message> is their message to
the bot, and C<vars> is a hash of any user variables your program might be
keeping track of (such as the user's name and age).

The response from C<rivescript> will look like the following:

  {
    "status": "ok",
    "reply":  "Hello, human!",
    "vars": {
      "name": "Aiden"
    }
  }

Here, C<status> will be C<"ok"> or C<"error">, C<reply> is the bot's response to
your message, and C<vars> is a hash of the current variables for the user (so
that your program can save them somewhere).

=head3 Standard Input or Data

By default, JSON mode will read from standard input to receive your JSON
message. As an alternative to this, you can provide the C<--data> option to
C<rivescript> to present the incoming JSON data as a command line argument.

This may be helpful if you don't want to open a two-way pipe to C<rivescript>,
and would rather pass your input as a command line argument and simply read
the response from standard output.

Example:

  $ rivescript --json --data '{"username": "localuser", "message": "hello" }' \
    /path/to/rs/files

This will cause C<rivescript> to print its JSON response to standard output
and exit. You can't have a stateful session using this method.

=head3 End of Message

There are two ways you can use the JSON mode: "fire and forget," or keep a
stateful session open.

In "fire and forget," you open the program, print your JSON input and send the
EOF signal, and then C<rivescript> sends you the JSON response and exits.

In a stateful session mode, you must send the text C<__END__> on a line by
itself after you finish sending your JSON data. Then C<rivescript> will
process it, return its JSON response and then also say C<__END__> at the end.

Example:

  {
    "username": "localuser",
    "message": "Hello bot!",
    "vars": {}
  }
  __END__

And the response:

  {
    "status": "ok",
    "reply": "Hello, human!",
    "vars": {}
  }
  __END__

This way you can reuse the same pipe to send and receive multiple messages.

=head2 TCP Mode

TCP Mode will make C<rivescript> listen on a TCP socket for incoming
connections. This way you can connect to it from a different program (for
example, a CGI script or a program written in a different language).

Example:

  $ rivescript --listen localhost:2001

TCP Mode behaves similarly to L<"JSON Mode">; the biggest difference is that
it will read and write using a TCP socket instead of standard input and
output. Unlike JSON Mode, however, TCP Mode I<always> runs in a stateful
way (the JSON messages must end with the text "C<__END__>" on a line by
itself). See L<"End of Message">.

If the C<__END__> line isn't found after 20 lines of text are read from
the client, it will give up and send the client an error message (encoded
in JSON) and disconnect it.

=head1 SEE ALSO

L<RiveScript>, the Perl RiveScript interpreter.

=head1 AUTHOR

Noah Petherbridge, http://www.kirsle.net

=head1 LICENSE

  RiveScript - Rendering Intelligence Very Easily
  Copyright (C) 2012 Noah Petherbridge
  
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
