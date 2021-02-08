package RogueQuest::room1;

use RogueQuest::gargoyle;

use parent 'RogueQuest::room';

sub new {
	my ($class, $x, $y) = @_;
	my $self = $class->SUPER::new($x, $y);

	push (@{ $self->entities},, RogueQuest::gargoyle->new(100,100)); 

	return $self;
}

1;
