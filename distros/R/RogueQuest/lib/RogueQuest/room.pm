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
		$self->{entities}->update;
		$self->{entities}->blit($screen_surface);
	}
}

sub moveleft {
	my ($self) = shift;

	$self->{x}--;
}

sub moveright {
	my ($self) = shift;

	$self->{x}++;
}

sub moveup {
	my ($self) = shift;

	$self->{y}--;
}

sub movedown {
	my ($self) = shift;

	$self->{y}++;
}

1;
