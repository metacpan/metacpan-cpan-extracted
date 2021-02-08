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
	my ($self, $roomx, $roomy, $screen_surface) = shift;
	my $image = $self->{imagestates}->get;

	SDL::Video::blit_surface( $image, SDL::Rect->new($self->{x}+$roomx, $self->{y}+$roomy, $image->w, $image->h), 	$screen_surface,  SDL::Rect->new($self->{x}+$roomx, $self->{y}+$roomy, $screen_surface->w,  $screen_surface->h) ); 
	SDL::Video::update_rect( $screen_surface, $self->{x}+$roomx, $self->{y}+$roomy, $screen_width, $screen_height );
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
