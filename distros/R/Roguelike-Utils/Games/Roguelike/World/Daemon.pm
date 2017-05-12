package Games::Roguelike::World::Daemon;

use strict;

use Games::Roguelike::Utils qw(:all);
use Games::Roguelike::Console::ANSI;
use Games::Roguelike::Mob;
use POSIX;

use IO::Socket;
use IO::Select;
use IO::File qw();		# this prevents warnings on win32

our $VERSION = '0.4.' . [qw$Revision: 253 $]->[1];

use Time::HiRes qw(time);

use base 'Games::Roguelike::World';

# purpose of module:
#
#     multi-user telnet daemon
#     finite-state processor, allows for single-thread engine

=head1 NAME

Games::Roguelike::World::Daemon - roguelike game telnet daemon

=head1 SYNOPSIS

 # for an extended example with move overrides, see the scripts/netgame included

 use strict;

 package myWorld;                                        # always override
 use base 'Games::Roguelike::World::Daemon';

 my $r = myWorld->new(w=>80,h=>50,dispw=>40,disph=>18);  # create a networked world
 $r->area(new Games::Roguelike::Area(name=>'1'));        # create a new area in this world called "1"
 $r->area->generate('cavelike');                         # make a cavelike maze

 while (1) {
        $r->proc();
 }

 sub readinput {                                         # called when input is available
        my $self = shift;
        if (my $c = $self->getch()) {                    # returns undef on failure
                if ($self->{vp}->kbdmove($c, 1)) {       # '1' in second param means "test only"
                        $r->queuemove($self->{vp}, $c);  # if the move is good, queue it
                }
        }
 }

 sub newconn {                                           # called when someone connects
        my $self = shift;
        my $char = mychar->new($self->area(1),           # create a new character
                sym=>'@',
                color=>'green',
                pov=>7
        );
        $self->{vp} = $char;                             # viewpoint is a connection state obect
        $self->{state} = 'MOVE';                         # set state (another state object)
}

 package mychar;
 use base 'Games::Roguelike::Mob';

=head1 DESCRIPTION

This module uses the Games::Roguelike::World object as the basis for a finite-state based
network game engine.

        * uses Games::Roguelike::Console::ANSI library to draw the current area
        * currently assumes Games::Roguelike::Mob's as characters in the game
        * currently assumes Games::Roguelike::Item's as items in the game

The module provides th eservice of accepting connections, maintainting he association between
the connection and a "state" and "viewpoint" for each connection, managing "tick" times, 
and rendering maps for each connection.

=head2 METHODS

=over

=cut

my $WIN32 = ($^O=~/win32/i);
my @SOCKS;

=item new ()

Similar to ::World new, but with arguments: host, port, and addr

This begins listening for connections, and sets up some signal handlers for 
graceful death.

=cut

sub new {
    	my $pkg = shift;
	my $r = $pkg->SUPER::new(@_, noconsole=>1);
    	bless $r, $pkg;

	$r->{tick} = 0.5 if !$r->{tick};

	local $! = 0;
	my %addrs;

        $addrs{LocalAddr} = $r->{addr} if $r->{addr};
        $addrs{LocalHost} = $r->{host} if $r->{host};
        $addrs{LocalPort} = $r->{port} if $r->{port};

	$r->{main_sock} = new IO::Socket::INET(
			%addrs,
			Listen => 1, 
			ReuseAddr => 1);

	die $! unless $r->{main_sock};

	$r->{stdout} = *STDOUT unless $r->{stdout};

	$r->{read_set} = new IO::Select();
	$r->{read_set}->add($r->{main_sock});
	$r->{write_set} = new IO::Select();

	push @SOCKS, $r->{main_sock};
	
	$SIG{__DIE__} = \&sig_die_handler;
	$SIG{INT} = \&sig_int_handler;

	return $r;
}

sub sig_int_handler {
	sig_die_handler();
	exit(0);
}

sub sig_die_handler {
	for (@SOCKS) {
		close($_);
	}
	undef @SOCKS;
	1;
}

sub DESTROY {
    	my $r = shift;
	if ($r->{main_sock}) {
		$r->{main_sock}->close();
	}
	$r->SUPER::DESTROY();
}

=item proc ()

Look for waiting input and calls:

	newconn() - for new conneciton
	readinput() - when input is available
	tick() - to process per-turn moves
	drawallmaps() - to render all the maps	

When those functions are called the class {vp} and {state} variables are 
set to the connection's "viewpoint" (character) and "state".

Also, the special scalar state 'QUIT' gracefully removes a connection. 

(It might be interesting to use code refs as states)

=cut

sub proc {
    my $self = shift;

#    $self->log("proc " . $self->{read_set}->count());

    my $now = time();
    $self->{ts} = $now unless $self->{ts};
    my $rem = max(0.1, $self->{tick} - ($now - $self->{ts}));

#    $self->log("rem", $rem);

    my ($new_readable, $new_writable, $new_error) = IO::Select->select($self->{read_set}, $self->{write_set}, $self->{read_set}, $rem + .01);

    foreach my $sock (@$new_readable) {
        if ($sock == $self->{main_sock}) {
            my $new_sock = $sock->accept();
	    $self->log("incoming connection from: " , $new_sock->peerhost());
            # new socket may not be readable yet.
	    if ($new_sock) {
		    push @SOCKS, $new_sock;
		    ++$self->{req_count};
		    if ($WIN32) {
		    	ioctl($new_sock, 0x8004667e, pack("I", 1));
		    } else {
		   	fcntl($new_sock, F_SETFL(), O_NONBLOCK());
		    }
		    $new_sock->autoflush(1);
		    my @opts;
		    # pass through some options to console object on new connections
		    for (qw(usereadkey noinit)) {
			push @opts, $_=>$self->{$_} if defined $self->{$_};
		    }
	            $self->{read_set}->add($new_sock);
		    *$new_sock{HASH}->{con} = new Games::Roguelike::Console::ANSI (in=>$new_sock, out=>$new_sock, @opts);
		    *$new_sock{HASH}->{time} = time();
		    *$new_sock{HASH}->{errc} = 0;
		    $self->{con} = *$new_sock{HASH}->{con};
		    $self->echo_off();
		    $self->{state} = '';
		    $self->{vp} = '';
		    $self->newconn($new_sock);	
		    *$new_sock{HASH}->{state} = $self->{state};
		    *$new_sock{HASH}->{char} = $self->{vp};
		    $self->{vp}->{con} = $self->{con} if $self->{vp} && !$self->{vp}->{con};
	    	    $self->log("state is: " , $self->{state});
	    }
        } else {
		if ($sock->eof() || !$sock->connected() || (*$sock{HASH}->{errc} > 5)) {
			$self->{state} = 'QUIT';
		} else {
		    	$self->log("reading from: " , $sock->peerhost());
		    	$self->log("state was: " , $self->{state});
			$self->{con} = *$sock{HASH}->{con};
			$self->{state} = *$sock{HASH}->{state};
			$self->{vp} = *$sock{HASH}->{char};
			$self->readinput($sock);
			*$sock{HASH}->{state} = $self->{state};
			*$sock{HASH}->{char} = $self->{vp};
		    	$self->{vp}->{con} = $self->{con} if $self->{vp} && !$self->{vp}->{con};
	    		$self->log("state is: " , $self->{state});
		}

		if ($self->{state} eq 'QUIT') {
			eval {
				*$sock{HASH}->{char}->{area}->delmob(*$sock{HASH}->{char}) if *$sock{HASH}->{char};
			};
			$self->{read_set}->remove($sock);
			$sock->close();
		} 
	}
    }
    foreach my $sock (@$new_error) {
	*$sock{HASH}->{char}->{area}->delmob(*$sock{HASH}->{char});
	$self->{read_set}->remove($sock);
	close($sock);
    }
    {
    my $now = time();
    my $rem = $now - $self->{ts};

    if ($rem >= $self->{tick}) {
        #$self->log("tick");
    	$self->tick();
    	$self->drawallmaps();
	$self->{ts} = $now;
    }
    }
}

sub drawallmaps {
    my $self = shift;
    foreach my $sock ($self->{read_set}->handles())  {
        if (*$sock{HASH}->{char}) {
                $self->{vp} = *$sock{HASH}->{char};
                $self->{con} = *$sock{HASH}->{con};
		$self->{area} = $self->{vp}->{area};
                my $color = $self->{vp}->{color};
                my $sym = $self->{vp}->{sym};
		$self->setfocuscolor();
                $self->drawmap();
		$sock->flush();
                $self->{vp}->{color} = $color;
                $self->{vp}->{sym} = $sym;
        }
    }
}

sub echo_off {
        my $self = shift;
	my $sock = $self->{con}->{out};
	# i will echo if needed, you don't echo, i will suppress go ahead, you do suppress goahead
	print $sock "\xff\xfb\x01\xff\xfb\x03\xff\xfd\x03";
}

sub echo_on {
        my $self = shift;
	my $sock = $self->{con}->{out};
	# i wont echo, you do echo
	print $sock "\xff\xfc\x01\xff\xfd\x01";
}

=item getstr ()

Reads a string from the active connection.

Returns undef if the string is not ready.

=cut

sub hexify {
	my ($s) = @_;
	my $ret = '';
	for (split(//,$s)) {
		$ret .= sprintf("x%x", ord($_));
		$ret .= "($_)" if $_ =~ /\w/;
	}
	return $ret;
}

sub getstr {
        my $self = shift;
	my $sock = $self->{con}->{in};
	my $first = 1;

	while (1) {
        	my $b = $self->getch();
        	if (!defined($b)) {
			++(*$sock{HASH}->{errc}) if $first;
                	return undef;
		} elsif($b eq 'BACKSPACE') {
			$self->log("getstr read $b");
			if (length(*$sock{HASH}->{sbuf}) > 0) {
	                        syswrite($sock, chr(8), 1);
	                        syswrite($sock, ' ', 1);
	                        syswrite($sock, chr(8), 1);
				substr(*$sock{HASH}->{sbuf},-1,1) = '';
			}
        	} elsif(length($b) > 1 || $b eq '') {
			next;
		} else {
			$self->log("getstr read " . ord($b));
			syswrite($sock,$b,1);	# echo on getstr
			$first = 0 if $first;
                	*$sock{HASH}->{errc} = 0;
			*$sock{HASH}->{sbuf} .= $b;
        	}
		if ($b eq "\n" || $b eq "\r") {
			my $temp = *$sock{HASH}->{sbuf};
			*$sock{HASH}->{sbuf} = '';
			return $temp;
		}
	}
}

=item getch ()

Reads a character from the active connection.

Returns undef if no input is ready.

=cut

sub getch {
	my $self = shift;
	my $c = $self->{con}->nbgetch();
	if (! defined $c) {
		my $sock = $self->{con}->{in};
		++(*$sock{HASH}->{errc}) 
	}
	return $c;
}

=item charmsg ($char)

Calls showmsg on the console contained in $char;

=cut

sub charmsg {
	my $self = shift;
	my ($char, $msg, $attr) = @_;
	my $con = $self->{con};
	$self->{con} = $char->{con};
	$self->showmsg($msg,$attr);
	$self->{con} = $con;	
}

# log and debug print are essentially the same thing

sub log {
	my $self = shift;
	my $out = $self->{stdout};
	print $out scalar(localtime()) . "\t" . join("\t", @_) . "\n";
}

sub dprint {
	my $self = shift;
	my $out = $self->{stdout};
	print $out scalar(localtime()) . "\t" . join("\t", @_) . "\n";
}

# override this for your game

# for now, the way we report back state changes is to modify
#
#   $self->{state}
#   $self->{vp} 	# for creating/loading/switching to a character's viewpoint
#
# these are then linked to the socket
#
# actual action/movement by a charcter should be queued here, then processed according to a random sort and/or a sort based
# on the speed of the character at tick() time
#
# ie: if an ogre and a sprite move during the same tick, the sprite always goes first, even if the 
# ogre's player has a faster internet connection
#
# use getch for a no-echo read of a character
# use getstr for an echoed read of a carraige return delimited string
#
# both will return undef if there's no input yet
# don't "wait" for anything in your functons, game is single threaded! 
#

=item readinput ()

Must override and call getch() or getstr().  

The {vp}, {state}, and {con} vars are set on this call, can be 
changed, and will be preserved.

Actual action/movement by a charcter should be queued here, then processed according to 
a random sort and/or a sort based on the speed of the character.

 For example: If a tank and a motorcycle move during the same tick, the motorcycle would always go first, even if the tank's player has a faster internet connection.  Queueing the moves allows you to do this.

Remember never to do something that blocks or waits for input, game is single-threaded.

=cut

sub readinput {
	die "need to overide this, see netgame example";
}

# override this for intro screen, please enter yor name, etc.
# use $self->{con} for the the Games::Roguelike::Console object (remember, chars are not actually written until flushed, which you can do here if you want)

=item newconn ()

Must override and either create a character or show an intro screen, or something.

The {vp}, {state}, and {con} vars are set on this call, can be changed, and will be preserved.

=cut

sub newconn {
	die "need to overide this, see netgame example";
}

=item setfocuscolor ()

Change the display color/symbol of the {vp} character here in order to distinguish it from other (enemy?) characters.

=cut

# change the symbol/color of the character when it's "in focus"
sub setfocuscolor {
        my $self = shift;
	$self->{vp}->{color} = 'bold yellow';
}

=item queuemove ($char, $move[, $msg])

Pushes a "move" for char $char showing message $msg.  By default will not queu if a move has been set.  The "move" variabe is set in the "char" object to record whether a move has occured.

=cut

# queue a move until tick time
sub queuemove {
        my $self = shift;
        my ($char, $move, $msg) = @_;
        if ($char->{move}) {
		# already moving, so do nothing
		# might what to show a message here
        } else {
                $self->showmsg($msg) if $msg;
                $self->{con}->refresh();
                $char->{move} = $move;
                push @{$self->{qmove}}, $char;
        }
}

# override this to sort the queue by character speed, display hit points, turn-counts or other status info, etc.
# override to process character and mob actions/movement map is auto-redrawn for all connections after the tick (if changed)
# don't try to draw here... since no character has the focus...it will fail 

=item tick ()

Override for per-turn move processing.   This is called for each game turn, which defaults to a half-second.
Default behavior is to sort all the queued moves and execute them.

A good way to handle this might be to make the "moves" be code references, which get passed "char" as the argument.

=cut

sub tick {
    my $self = shift;
    my @auto;
    foreach my $char (randsort(@{$self->{qmove}})) {
        $char->kbdmove($char->{move});
        $char->{move} = '';
    }
}

=back

=head1 BUGS

Currently this fails on Win32

=head1 SEE ALSO

L<Games::Roguelike::World>

=head1 AUTHOR

Erik Aronesty C<earonesty@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html> or the included LICENSE file.

=cut

1;
