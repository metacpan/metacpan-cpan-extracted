package RogueCurses::RNG;

### stats dice rolling system (Random Number God)

sub new {
	my ($class) = @_;
	my $self = {};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub rollX {
	my ($self, $x) = shift;

	return int(rand($x)) + 1;
}

sub rolld6 {
	my $self = shift;

	return $self->rollX(6); 
}

sub rolld3 {
	my $self = shift;

	return $self->rollX(3); 
}

sub rolld2 {
	my $self = shift;

	return $self->rollX(2); 
}

sub rolld4 {
	my $self = shift;

	return $self->rollX(4); 
}

sub rolld18 {
	my $self = shift;

	return $self->rollX(18); 
}


1;
