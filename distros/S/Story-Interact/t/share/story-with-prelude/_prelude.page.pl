$Local::Character::Human::DEFINED or eval q{
	package Local::Character::Human;
	use Moo;
	extends 'Story::Interact::Character';
	sub introduction {
		my $self = shift;
		sprintf( "My name is %s", $self->name );
	}
	our $DEFINED = 1;
};

define_npc bob => (
	name  => 'Bob',
	class => 'Local::Character::Human',
);
