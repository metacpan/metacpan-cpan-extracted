package RogueCurses::NPCs::trenchgnomeinterface;

use Curses;
use parent 'RogueCurses::rogueinterface';

sub new {
	my ($class, $name) = @_;
	my $self = $class->SUPER::new($name);

	$self->{messages} = {};
	$self->{$name} = $name or 'trench gnome';	
	$self->{messages}[0] = 'The ' . $name . ' remains silent';

}

sub compare_and_execute
{
	my $self = shift;
	my $key = shift;
	my $entity = shift;

}

1;
