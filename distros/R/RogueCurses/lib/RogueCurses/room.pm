package RogueGame::room;

sub new {
	my ($class, $x,$y) = @_;
	my $self = { x => $x, y => $y, entities => (), };

	$class = ref($class) || $class;

	bless $self, $class;
}

sub update {
	my ($self, $screen_surface) = @_;

	for (my $i = 0; $i < length($self->{entities}); $i++) {
		$self->{entities}->update;
		$self->{entities}->blit($screen_surface);
	}
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
