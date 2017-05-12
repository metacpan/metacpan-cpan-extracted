use 5.010;
use MooseX::DeclareX
	keywords => [qw(class exception)],
	plugins  => [qw(guard)],
	;

exception BananaError
{
	has origin => (
		is       => 'rw',
		isa      => 'Monkey',
		required => 1,
	);
}

class Monkey
{
	has name => (
		is       => 'rw',
		isa      => 'Str',
		required => 1,
	);
	has bananas => (
		is       => 'rw',
		isa      => 'Int',
		traits   => ['Counter'],
		handles  => {
			give_banana  => 'inc',
			eat_banana   => 'dec',
			lose_bananas => 'reset',
		},
		default  => 0,
		required => 1,
	);
	
	guard eat_banana {
		$self->bananas or	BananaError->throw(
			origin  => $self,
			message => "We have no bananas today!",
		)
	}
	
	after lose_bananas {
		try { say "Oh no!" }
	}
	
	method trace {
		printf "%s has %d bananas.\n", $self->name, $self->bananas
	}
}

try {
	my $bobo = Monkey->new(name => 'Bobo');
	$bobo->give_banana;
	$bobo->lose_bananas;
	$bobo->give_banana;
	$bobo->eat_banana;
	$bobo->eat_banana;
}
catch (BananaError $e) {
	say ref $e;
}