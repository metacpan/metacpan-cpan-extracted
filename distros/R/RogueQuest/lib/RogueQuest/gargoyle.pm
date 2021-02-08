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

1;
