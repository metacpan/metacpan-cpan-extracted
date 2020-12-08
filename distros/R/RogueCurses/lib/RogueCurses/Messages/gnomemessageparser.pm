package RogueCurses::Messages::gnomemessageparser;

use parent 'RogueCurses::messageparser';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new;

}

### partial grep of parser, returns probability
sub parse_speed_partial_grep {
	my ($self, $msg) = @_;

	
}

1;
