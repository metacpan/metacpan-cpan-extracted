package RogueCurses::surroundings;

sub new {
	my ($class, @words) = @_;
	my $self = {
		words => @words, 
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub is_dungeon {
	my $self = shift;
	
	return grep(/(D|d)ungeon/, $self->words);
}

sub is_wood {
	my $self = shift;
	
	return grep(/(W|w)ood|(F|f)orest/, $self->words);
}

1;
