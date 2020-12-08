package RogueQuest::entity;

###no strict 'refs';

use SDL::Video;

use RogueQuest::stateimagelibrary;

sub new {
	my $class = shift;
	my $self = { $x = shift, $y = shift, $w = shift, $h = shift, 
			$imagestates = RogueQuest::stateimagelibrary->new(), };

	$class = ref($class) || $class;

	bless $self, $class;
}

sub update {
	my $self = shift;

	### FIXME
	$self->{x}++;
}

sub blit {
	my ($self, $screen_surface) = shift;
	my $image = $self->{imagestates}->get;

	SDL::Video::blit_surface( $image, SDL::Rect->new($self->{x}, $self->{y}, $image->w, $image->h), 	$screen_surface,  SDL::Rect->new($self->{x}, $self->{y}, $screen_surface->w,  $screen_surface->h) ); 
	SDL::Video::update_rect( $screen_surface, $x, $y, $screen_width, $screen_height );
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
