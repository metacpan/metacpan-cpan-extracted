package FSM_01;

#use Moose;
use MooseX::FSM;

has state1 => (
	is			=> 'ro',
	enter		=> \&init,
	input		=> { input1 => \&func_1, input2 => \&func_2 },
	traits		=> ['State'],
	transitions	=> { input1 => 'state1', input2 => 'state2' },
);

has state2 => (
	is		=> 'ro',
	input		=> { input3 => \&func_3, input5 => sub { return "anon" },  },
	traits		=> ['State'],
	transitions	=> { input3 => 'state4' },
);

has state3 => (
	is		=> 'ro',
	inputs	=> { input4 => \&func_4 },
	traits	=> ['State'],

);

has state4 => (
	is			=> 'ro',
	inputs		=> { input4 => \&func_4 },
	traits		=> ['State'],
	transitions => { input4 => 'state3' },
);

has state5 => (
	is		=> 'ro',
	inputs		=> { input5 => \&func_5 },
	traits		=> ['State'],
#	transitions => { input 
);
sub init {
	my $self = shift;
	Test::More::pass('init function called');
}

sub func_1 {
	my $self = shift;
	return "func_1";
}

sub func_2 {
	my $self = shift;
	return "func_2";
}

sub func_3 {
	my $self = shift;
	return "func_3";
}


sub func_4 {
	my $self = shift;
	return "func_4";
}

no MooseX::FSM;

1;
