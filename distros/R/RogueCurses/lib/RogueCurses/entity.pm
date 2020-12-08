package RogueCurses::entity;

use RogueCurses::rogueinterface;
use RogueCurses::entitystate;

sub new {
	my ($class,$x,$y,$w,$h, $chr, $interface) = @_;
	my $self = { x => $x, y => $y, w => $w, h => $h,
		mychar => $chr or 'e', 
		stats => RogueCurses::entitystate->new, # str, dex, etc
		messages = $interface->{messages}  # echo prints
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

### default entity command execution returns < 0
sub compare_and_execute {
	my ($self, $key) = @_;
	return -99;
}

sub get_message {
	my $self = shift;
	my $n = shift;

	### FIXME entity speaks
}

sub interface_get_message {
	my $self = shift;
	my $n = shift;

	return $self->{messages}[$n];
} 

sub update_with_rogue_interface {
	my ($self, $rint) = @_;

}

sub blit {
	my ($self, $screen) = shift;

	$screen->blit_entity($self);
}

sub move_left {
	my ($self) = shift;

	$self->{x}--;
}

sub move_right {
	my ($self) = shift;

	$self->{x}++;
}

sub move_up {
	my ($self) = shift;

	$self->{y}--;
}

sub move_down {
	my ($self) = shift;

	$self->{y}++;
}

1;
