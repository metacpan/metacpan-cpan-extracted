use strict;
package Games::Roguelike::Console::Curses;
use Curses qw(noecho cbreak curs_set start_color);
use base qw(Curses::Window Games::Roguelike::Console);
use Carp qw(croak cluck);
use POSIX;
use warnings::register;

our $VERSION = '0.4.' . [qw$Revision: 233 $]->[1];

my $ATTR = 0;

sub new {
        my $pkg = shift;
        croak "usage: Games::Roguelike::Console::Curses->new()" unless $pkg;

        my $r = new Curses qw();
	bless $r, $pkg;
        $r->init(@_);
        return $r;
}

my %COLORS;

my $KEY_LEFT = Curses::KEY_LEFT;
my $KEY_RIGHT = Curses::KEY_RIGHT;
my $KEY_DOWN = Curses::KEY_DOWN;
my $KEY_UP = Curses::KEY_UP;
my $KEY_DELETE = Curses::KEY_DC;
my $KEY_BACKSPACE = Curses::KEY_BACKSPACE;
my %CONDATA;

sub init {
	my $self = shift;
	my %opts = @_;
	if (!$opts{noinit}) {
		$self->keypad(1);
		$self->color_init();
		$self->SUPER::init(%opts);
		curs_set(0);
		noecho();
		cbreak();
		$SIG{INT} = \&sig_int_handler;		# endwin b4 die text comes out
		$SIG{__DIE__} = \&sig_die_handler;		# endwin b4 die text comes out
	}
}

sub color_init {
	no strict 'refs';
        start_color();
	my $i = 0;
	for my $fg (qw(white blue cyan green yellow magenta black red)) {
	for my $bg (qw(black white blue cyan green yellow magenta red)) {
		$COLORS{$fg}{$bg} = ++$i;
        	Curses::init_pair($COLORS{$fg}{$bg},&{"Curses::COLOR_".uc($fg)}, &{"Curses::COLOR_".uc($bg)});
	}}
	use strict 'refs';
}

sub sig_die_handler {
	die @_ if $^S;
	Curses::endwin();
	die @_;
}

sub sig_int_handler {
        Curses::endwin();
	exit;
}

sub DESTROY {
	Curses::endwin();
	if ($^O =~ /linux|darwin/) {
		if (my $tty = POSIX::ttyname(1)) {
			system("stty -F $tty sane");
		}
	}
}

sub nativecolor {
	my ($self, $fg, $bg, $bold) = @_;
	if (warnings::enabled() && !$COLORS{$fg}{$bg}) {
		cluck("Uninitialized color pair ($fg-$bg)");
	}
	return Curses::COLOR_PAIR($COLORS{$fg}{$bg}) | ($bold ? Curses::A_BOLD : 0);
}

sub tagstr {
        my $self = shift;

        my ($y, $x, $str);

        if (@_ >= 3) {
                ($y, $x, $str) = @_;
		$self->move($y, $x);
        } elsif (@_ == 1) {
                ($str) = @_;
        }

	return if !defined($str);

        my $hasattr;
        my $c;
        for (my $i = 0; $i < length($str); ++$i) {
                $c = substr($str,$i,1);
                if ($c eq '<') {
                        substr($str,$i) =~ s/^<([^>]*)>//;
			if ($1 eq 'gt') {
				$c = '>';
				--$i;
			} elsif ($1 eq 'lt') {
				$c = '<';
				--$i;
			} else {
				if ($1) {
					$self->attron($1); 
					$hasattr = 1;
				} else {
					$self->attroff();
				}
                        	$c = substr($str,$i,1);
			}
                }
		$self->addch($c);
        }
	$self->attroff() if $hasattr;
}

sub attron {
        my $self = shift;
        my ($attr) = lc(shift);
	if ($ATTR) {
        	$self->SUPER::attroff($ATTR);
	}
	$ATTR = $self->parsecolor($attr);
	$self->SUPER::attron($ATTR);
}

sub attroff {
        my $self = shift;
        $self->SUPER::attroff($ATTR);
	$ATTR = 0;
}

sub getch {
        my $self = shift;
        my $c =$self->SUPER::getch();
	if ($c eq $KEY_UP) {
		return 'UP';
	} elsif ($c eq $KEY_DOWN) {
		return 'DOWN';
	} elsif ($c eq $KEY_LEFT) {
		return 'LEFT';
	} elsif ($c eq $KEY_RIGHT) {
		return 'RIGHT';
	} elsif ($c eq $KEY_DELETE) {
		return 'DELETE';
	} elsif ($c eq $KEY_BACKSPACE) {
		return 'BACKSPACE';
	} elsif (ord($c) == 27) {
		return 'ESC';
	}
        return $c;
}

sub nbgetch {
        my $self = shift;
	$self->nodelay(1);
	my $c =$self->getch();
	$self->nodelay(0);
	return $c;
}

sub cursor {
        my $self = shift;
	curs_set($_[0])
}

sub redraw {
	my $self=shift;
	$self->redrawwin();
}

1;
