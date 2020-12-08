package RogueCurses::Messages::messagesdb;

use RogueCurses::Messages::messageparser;
use RogueCurses::Messages::gnomemessageparser;

sub new {
	my ($class) = @_;

	$self->{NPCmessages} = {};


	$class = ref($class) || $class;

	bless $self, $class;
}

### NOTE : $nameofentity dynamically bound 
sub gen_NPCmessages
{
	my ($self) = shift;

	$self->{NPCmessages}[0] = $nameofentity . ' remains silent';
	
}

### use a message parser for seeking a sample of return messages
sub interpolate_character {
	my ($self, $fieldedmsg, $nameofentity, $surroundings) = @_;

	if ($nameofentity =~ m/(G|g)nome/) { ### FIXME match nome of gnome
		my $msgparser = RogueCurses::Messages::gnomemessageparser;
	
		### draw sample from parsed messages, @samples are probabilities
		my @samples = (
			$msgparser->parse_speed_partial_grep($fieldedmsg, $surroundings), 
		);
	}

}

1;
