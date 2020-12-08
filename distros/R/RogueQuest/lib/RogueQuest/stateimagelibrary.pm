package RogueQuest::stateimagelibrary;

use SDL::Image;

sub new {
	my $class = shift;
	my $self = { $index = 0, @images = (), };

	$class = ref($class) || $class;

	bless $self, $class;
}

sub add {
	my ($self, $imgfilename) = shift;

	### load the image file and put it in the state list
	my $img = SDL::Image::load($imgfilename);
	my @a = $self->{images};
	push (@a, $img);
}

sub get {
	my ($self) = shift;

	if ($self->{index} >= length($self->{images}))
	{
		$self->{index} = 0;
	}	

	return $self->{images}[$self->{index}++];
}
	
1;
