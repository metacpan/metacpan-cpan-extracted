package RogueQuest::room1;

use RogueQuest::gargoyle;

use parent 'RogueQuest::room';

sub new {
	my ($class, $x, $y) = @_;
	my $self = $class->SUPER::new($x, $y);

	###$class = ref($class) || $class;

	###return bless $self, $class;
	#

###my $entity = RogueQuest::entity->new(100,100,48,48);
###print "---> " . $entity . " ---> " . $entity->{imagestates} . "\n";
###$entity->{imagestates}->add("./pics/gargoyle1.png");

	
	my @a = $self->{entities};
	push (@a, RogueQuest::gargoyle->new(100,100)); 

	return $self;
}

1;
