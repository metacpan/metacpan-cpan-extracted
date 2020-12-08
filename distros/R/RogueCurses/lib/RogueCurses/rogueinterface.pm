package RogueCurses::rogueinterface;

use Curses;
use parent 'RogueCurses::interface';

sub new {
	my ($class, $name) = @_;
	my $self = $class->SUPER::new;

	$self->{name} = $name or 'entity';
	$self->{messages} = {};
}

### work out the effect of the key/char on the entity
sub dispatch_key {
	my $self = shift;
	my $key = shift;
	my $entity = shift;

	### dispatch the key to the entity
	if ((my $n = $entity->compare_and_execute($key)) >= 0) {
		### return the message after the use of the key
		return $entity->interface_get_message($n);	
	} else { 
		### if the entity does not respond >= 0, you handle it 
		### by the default engine, this one
		return $self->compare_and_execute($key, $entity);
	} 
}

sub compare_and_execute
{
	my $self = shift;
	my $key = shift;
	my $entity = shift;

	### dummy method, < 0 fails
	return -99;
}

1;
