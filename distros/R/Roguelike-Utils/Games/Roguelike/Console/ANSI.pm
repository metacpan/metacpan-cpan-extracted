package Games::Roguelike::Console::ANSI;

=head1 NAME

Games::Roguelike::Console::ANSI - socket-friendly, object oriented curses-like support for an ansi screen buffer

=head1 SYNOPSIS

 use Games::Roguelike::Console::ANSI;

 $con = Games::Roguelike::Console::ANSI->new();
 $con->attron('bold yellow');
 $con->addstr('test');
 $con->attroff();
 $con->refresh();

=head1 DESCRIPTION

Allows a curses-like ansi screen buffer that works on win32, and doesn't crash when used with 
sockets like the perl ncurses does.

Inherits from Games::Roguelike::Console.  See Games::Roguelike::Console for list of methods.

Uses Term::ANSIColor for colors.  

=head1 SEE ALSO

L<Games::Roguelike::Console>

=head1 AUTHOR

Erik Aronesty C<earonesty@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html> or the included LICENSE file.

=cut

use strict;
use IO::File;
use Term::ReadKey;
use Term::ANSIColor;
use POSIX;
use Carp qw(confess croak);

use base 'Games::Roguelike::Console';

our $VERSION = '0.4.' . [qw$Revision: 258 $]->[1];

our $KEY_ESCAPE = chr(27);
our $KEY_NOOP = chr(241);
our ($KEY_LEFT, $KEY_UP, $KEY_RIGHT, $KEY_DOWN) = ('[D','[A','[C','[B');

my %TELKEY = (
	"\xfb" => 'WILL',
	"\xfc" => 'WONT',
	"\xfd" => 'DO',
	"\xfe" => 'DONT',
);

sub new {
        my $pkg = shift;
        croak "usage: Games::Roguelike::Console::ANSI->new()" unless $pkg;

        my $self = bless {}, $pkg;
        $self->init(@_);
        return $self;
}

my $STD;
sub init {
	my $self = shift;

	my %opt = @_;

	$self->{in} = *STDIN{IO} unless $self->{in} = $opt{in};
	$self->{out} = *STDOUT{IO} unless $self->{out} = $opt{out};
 	$self->{cursor} = 1;
	$self->{cx} = 0;
	$self->{cy} = 0;
	$self->{cattr} = '';
	$self->{cbuf} = '';
	$self->{reset} = color('reset');

	$self->SUPER::init(%opt);	

	# initialize ansi terminal
	if (!$opt{noinit}) {

		my $out = $self->{out};

		$self->{usereadkey} = (($self->{out}->fileno() == 1));

		# i think get away from readkey
		# and just send the ansi sequence 
		# for determining terminal size

		if ($self->{usereadkey}) {
			# this will (wrongly) close the output handle if it fails
			eval {
				($self->{winx}, $self->{winy}) = GetTerminalSize($self->{out});
				ReadMode 'cbreak', $self->{in};
			};
		}

		if (!$self->{winx}) {
			# todo: negotiate using telnet stuff
			($self->{winx}, $self->{winy}) = (80,40);
		}
		
		$self->{invl}=$self->{winx}+1;
		$self->{invr}=-1;
		$self->{invt}=$self->{winy}+1;
		$self->{invb}=-1;


		print $out ("\033[2J"); 	#clear the screen 
		print $out ("\033[0;0H"); 	#jump to 0,0
		print $out ("\033[=0c"); 	#hide cursor

		$self->{cursor} = 0;
		if ($self->{out}->fileno() == 1) {
			# there's probably a tty
			$STD = $self;
			$SIG{INT} = \&sig_int_handler;
			$SIG{__DIE__} = \&sig_die_handler;
			$self->{speed} = `stty speed` unless $self->{speed};
		}
	}
}

sub clear {
	my $self = shift;
	my $out = $self->{out};
	@{$self->{buf}} = [];
	@{$self->{cur}} = [];
	print $out ("\033[2J"); 	#clear the screen 
	print $out ("\033[0;0H"); 	#jump to 0,0
}

sub redraw {
	my $self = shift;
	my $out = $self->{out};
        @{$self->{cur}} = [];
	print $out "\033c"; 		# reset
	print $out ("\033[=0c") if !$self->{cursor}; 	# hide cursor
	$self->clear();
	refresh();
}

sub reset_fh {
	my $out = shift;
	#print $out "\033[c"; 		# reset
	print $out "\033[=1c"; 		# show cursor
	print $out "\033[30;0H";     	# jump to col 0
	eval {ReadMode 0, $out};	# normal input
}

sub sig_int_handler {
	reset_fh(*STDOUT{IO});
	exit;
}

sub sig_die_handler {
	die @_ if $^S;
	reset_fh(*STDOUT{IO});
	die @_;
}

sub END {
	# this is only done because DESTROY is never called for some reason on Win32
	if ($STD) {
		reset_fh(*STDOUT{IO});
		$STD = undef;
	}

	if ($^O =~ /linux|darwin/) {
		if (my $tty = POSIX::ttyname(1)) {
			system("stty -F $tty sane");
		}
	}
}

sub DESTROY {
	my $self = shift;
	if ($self->{out} && fileno($self->{out})) {
        reset_fh($self->{out});
        if ($self->{out}->fileno() 
		&& $self->{out}->fileno() == 1) {
		$STD = undef;
                $SIG{INT} = undef;
                $SIG{__DIE__} = undef;
        }
	}
}

sub tagstr {
	my $self = shift;
	my ($y, $x, $str);
	if (@_ == 1) {
		($y, $x, $str) = ($self->{cy}, $self->{cx}, @_);
	} else {
		($y, $x, $str) = @_;
	}
	my $attr;
	my $r = $x;
        my $c;
	for (my $i = 0; $i < length($str); ++$i) {
		$c = substr($str,$i,1);
		if ($c eq '<') {
			substr($str,$i) =~ s/<([^>]*)>//;
			$attr = $1;
        		$attr =~ s/(bold )?gray/bold black/i;
        		$attr =~ s/,/ /;
        		$attr =~ s/\bon /on_/;
			if ($attr eq 'gt') {
				$c = '>';
				--$i;
			} elsif ($attr eq 'lt') {
				$c = '<';
				--$i;
			} else {
				$c = substr($str,$i,1);
			}
		}
		if ($c eq "\r") {
			next;
		}
		if ($c eq "\n") {
			$r = 0;
			$y++;
			next;
		}
                $self->{buf}->[$y][$r]->[0] = $self->parsecolor($attr);
                $self->{buf}->[$y][$r]->[1] = $c;
		++$r;
	
        }
        $self->invalidate($x, $y, $x+$r, $y);
        $self->{cy}=$y;
        $self->{cx}=$x+$r;
}

sub parsecolor {
	my $self = shift;
	my $color = shift;
	if ($color) {
	        $color =~ s/(bold )?gray/bold black/i;
	        $color =~ s/,/ /;
		$color =~ s/\bon\s+/on_/;
		return color($color);
	} else {
		return '';
	}
}

sub attron {
	my $self = shift;
	$self->{cattr} = $self->parsecolor(@_);
}

sub attroff {
	my $self = shift;
	my ($attr) = @_;
	$self->{cattr} = '';
}

sub addstr {
	my $self = shift;
	my $str =  pop @_;

	if (@_== 0) {
		for (my $i = 0; $i < length($str); ++$i) {
			my $c = substr($str,$i,1);
			if ($c eq "\n") {
				$self->{cx} = 0;
				$self->{cy}++;
				next;
			}
			$self->{buf}->[$self->{cy}][$self->{cx}+$i]->[0] = $self->{cattr};
			$self->{buf}->[$self->{cy}][$self->{cx}+$i]->[1] = $c;
		}
		$self->invalidate($self->{cx}, $self->{cy}, $self->{cx} + length($str), $self->{cy});
		$self->{cx} += length($str);
	} elsif (@_==2) {
		my ($y, $x) = @_;
		for (my $i = 0; $i < length($str); ++$i) {
			my $c = substr($str,$i,1);
			if ($c eq "\n") {
				$c = 0;
				$y++;
				next;
			}
			$self->{buf}->[$y][$x+$i]->[0] = $self->{cattr};
			$self->{buf}->[$y][$x+$i]->[1] = $c;
		}
		$self->invalidate($x, $y, $x+length($str), $y);
		$self->{cy}=$y;
		$self->{cx}=$x+length($str);
	}
}

sub invalidate {
	my $self = shift;
        my ($l, $t, $r, $b) = @_;
        $r = 0 if ($r < 0);
        $t = 0 if ($t < 0);
        $b = $self->{winy} if ($b > $self->{winy});
        $r = $self->{winx} if ($r > $self->{winx});

        if ($r < $l) {
                my $m = $r;
                $r = $l;
                $l = $m;
        }
        if ($b < $t) {
                my $m = $t;
                $b = $t;
                $t = $m;
        }
        $self->{invl} = $l if $l < $self->{invl};
        $self->{invr} = $r if $r > $self->{invr};
        $self->{invt} = $t if $t < $self->{invt};
        $self->{invb} = $b if $b > $self->{invb};
}

sub refresh {
	my $self = shift;
	my $out = $self->{out};

	# it's expected that the "buf" array will frequently be uninitialized
	no warnings 'uninitialized';
	
	my $cc;
	for (my $y = $self->{invt}; $y <= $self->{invb}; ++$y) {
	for (my $x = $self->{invl}; $x <= $self->{invr}; ++$x) {
	if (!($self->{buf}->[$y][$x]->[0] eq $self->{cur}->[$y][$x]->[0]) || !($self->{buf}->[$y][$x]->[1] eq $self->{cur}->[$y][$x]->[1])) {
		print $out "\033[", ($y+1), ";", ($x+1), "H", @{$self->{buf}->[$y][$x]};
		$cc  += 9;
		$self->{cur}->[$y][$x]->[0]=$self->{buf}->[$y][$x]->[0];
		$self->{cur}->[$y][$x]->[1]=$self->{buf}->[$y][$x]->[1];
		my $pattr = $self->{cur}->[$y][$x]->[0];
		# reduce unnecessary cursor moves & color sets
		while ($x < $self->{invr} && 
			!(   ($self->{buf}->[$y][$x+1]->[0] eq $self->{cur}->[$y][$x+1]->[0]) 
			  && ($self->{buf}->[$y][$x+1]->[1] eq $self->{cur}->[$y][$x+1]->[1])
			 )
		      ) {
			++$x;
			if (!($pattr eq $self->{buf}->[$y][$x]->[0])) {
				print $out $self->{reset};
				print $out $self->{buf}->[$y][$x]->[0];
				$pattr = $self->{buf}->[$y][$x]->[0];
				$cc  += 7;
			}
			print $out $self->{buf}->[$y][$x]->[1];
			$self->{cur}->[$y][$x]->[0]=$self->{buf}->[$y][$x]->[0];
			$self->{cur}->[$y][$x]->[1]=$self->{buf}->[$y][$x]->[1];
			$cc  += 1;
		}
		print $out $self->{reset};
		$cc  += 4;
	}
	}
	}
	$self->{invl}=$self->{winx}+1;	
	$self->{invr}=-1;	
	$self->{invt}=$self->{winy}+1;	
	$self->{invb}=-1;
}

sub move {
	my $self = shift;
	my $out = $self->{out};
	my ($y, $x) = @_;
	$self->{cy}=$y;
	$self->{cx}=$x;
	if ($self->{cursor} && !($self->{cx}==$self->{scx} && $self->{cx}==$self->{scy})) {
		print $out "\033[", ($y+1), ";", ($x+1), "H";
		$self->{scx} = $self->{cx};
		$self->{scy} = $self->{cy};
	}
}

sub cursor {
	my $self = shift;
	my ($set) = @_;
	my $out = $self->{out};
	
	if ($set && !$self->{cursor}) {
		print $out ("\033[=1c");        #show cursor
		$self->{cursor} = 1;
		$self->move($self->{cy}, $self->{cx});
	} elsif (!$set && $self->{cursor}) {
		print $out ("\033[=0c");        #hide cursor
		$self->{cursor} = 0;
	}	
}

sub addch {
	my $self = shift;
	$self->addstr(@_);
}

sub getch_raw {
	my $self = shift;
	my $time = shift;
	if ($self->{usereadkey}) {
		return ReadKey($time ? $time : 0, $self->{in});
	} else {
		my $c;
		$c = undef if !sysread($self->{in}, $c, 1);
		return $c;
	}
}

sub trans {
	my ($c) = @_;

        if ($c eq $KEY_UP) {
                return 'UP'
        } elsif ($c eq $KEY_DOWN) {
                return 'DOWN'
        } elsif ($c eq $KEY_LEFT) {
                return 'LEFT'
        } elsif ($c eq $KEY_RIGHT) {
                return 'RIGHT'
        } elsif ($c eq "\x8") {
                return 'BACKSPACE'
        }

        return $c;
}

sub getch {
	my $self = shift;

	my $c;	
	if ($self->{cbuf}) {
		$c = substr($self->{cbuf},0,1);
		$self->{cbuf} = substr($self->{cbuf},1);
	} else {
		$c = $self->getch_raw();
	}

	if ($c eq $KEY_ESCAPE) {
		$c = $self->getch_raw(1);
		if ($c eq '[') {
			$c = $self->getch_raw(1);
			$c = '[' . $c;
		} elsif ($c eq $KEY_NOOP) {
			return getch();
		} elsif ($c eq $KEY_ESCAPE) {
			return 'ESC';
		} else {
			# unknown escape sequence
			$self->{cbuf} .= $c;
			return 'ESC';
		}
	}

	return trans($c);
}

sub nbgetch_raw {
        my $self = shift;
        my $c;
        if (length($self->{cbuf}) > 0) {
                $c = substr($self->{cbuf},0,1);
                $self->{cbuf} = substr($self->{cbuf},1);
        } else {
		if ($self->{usereadkey}) {
			$c = ReadKey(-1, $self->{in});
		} else {
			sysread($self->{in}, $c, 1);
		}
        }
	return $c;
}

sub nbgetch {
        my $self = shift;

	my $c = $self->nbgetch_raw();

	if ($c eq $KEY_ESCAPE) {
		my $c2 = $self->nbgetch_raw();
		if (!defined($c2)) {
			$self->{cbuf} = $KEY_ESCAPE;
			$c = '';
		} elsif ($c2 eq '[') {
			my $ct = '';
			my $cs = '';

			do {
				$ct = $self->nbgetch_raw();
				$cs .= $ct if defined $ct;
			} while (defined $ct && $ct !~ /^[a-z]$/i);

			if (!defined($ct)) {
				$self->{cbuf} = $KEY_ESCAPE . '[' . $cs;
			} else {
				$c = '[' . $cs;
			}
		} elsif ($c2 eq $KEY_NOOP) {
			$c = '';
		} elsif ($c2 eq $KEY_ESCAPE) {
			$c = 'ESC';
		} else {
			$c = $c2;
			$c = '' if ord($c) > 240;
		}
	} elsif (ord($c) == 255) {		# telnet esc
		my $c2 = $self->nbgetch_raw();
                if (!defined($c2)) {
                        $self->{cbuf} = $c;
                        $c = '';
		} elsif ($TELKEY{$c2}) {
			# telnet do/don't
                        my $c3 = $self->nbgetch_raw();
                        if (!defined($c3)) {
                                $self->{cbuf} = $c . $c2;
                        } else {
                                $c = $TELKEY{$c2} . ord($c3);
                        }
                } else {
                        $c = $c2;
                        $c = '' if ord($c) > 240;
                }
	}

	return trans($c);
}

1;
