package RogueCurses::screen;

use Curses;

my $ROGUE_WINDOW_WIDTH = 20;
my $ROGUE_WINDOW_HEIGHT = 10;

sub new {
	my ($class, $w, $h) = @_;

	$w = $ROGUE_WINDOW_WIDTH unless $w;
	$h = $ROGUE_WINDOW_HEIGHT unless $h;

	my $self = { scr => initscr, win => newwin(0,0,$w,$h), };

	$class = ref($class) || $class;
	bless $self, $class;
}

sub update_window {
	my $self = shift;

	wrefresh($self->{win});
}

sub update_screen {
	my $self = shift;

	$self->{scr}->refresh();
}

sub blit_char_in_window {
	my ($self, $x,$y, $char) = @_;

	mvwaddch($self->{win}, $y, $x, $char);
}

sub blit_entity {
	my ($self, $e) = @_;
	$self->blit($e->{x}, $e->{y}, $e->{mychar});
}

sub close {
	my $self = shift;
	endwin;
}
1;
