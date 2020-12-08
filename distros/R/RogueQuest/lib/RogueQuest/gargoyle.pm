package RogueQuest::gargoyle;

use SDL::Video;

use RogueQuest::stateimagelibrary;

use parent 'RogueQuest::entity';

sub new {
	my ($class, $x, $y) = @_;


	my $self = $class->SUPER::new($x,$y,48,48);

	$self->{imagestates} = new RogueQuest::stateimagelibrary;

	$self->{imagestates}->add("./pics/gargoyle1.png");

	### FIXME ?
	return $self;
}

sub update {
	my $self = shift;

	### FIXME
}

sub blit {
	my ($self, $screen_surface) = shift;

	SDL::Video::blit_surface( $image, SDL::Rect->new($x++, $y, $image->w, $image->h), 	$screen_surface,  SDL::Rect->new($x, $y, $screen_surface->w,  $screen_surface->h) ); 
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
