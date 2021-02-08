package RogueQuest::room;

sub new {
	my $class = shift;
	my $self = { $x = shift, $y = shift, @entities = (), };

	$class = ref($class) || $class;

	bless $self, $class;
}

sub update {
	my ($self, $screen_surface) = @_;

	for (my $i = 0; $i < length($self->{entities}); $i++) {
		$self->{entities}[$i]->update;
		$self->{entities}[$i]->blit($self->{x}, $self->{y}, $screen_surface);
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
