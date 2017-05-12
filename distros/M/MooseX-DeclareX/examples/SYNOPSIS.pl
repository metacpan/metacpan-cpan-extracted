use 5.010;
use MooseX::DeclareX
	keywords => [qw(class exception)],
	plugins  => [qw(guard build preprocess)],
	;

class Banana;

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
	);

	build name {
		state $i = 1;
		return "Anonymous $i";
	}	
	
	has bananas => (
		is       => 'rw',
		isa      => 'ArrayRef[Banana]',
		traits   => ['Array'],
		handles  => {
			give_banana  => 'push',
			eat_banana   => 'shift',
			lose_bananas => 'clear',
			got_bananas  => 'count',
		},
	);
		
	build bananas {
		return [];
	}
	
	guard eat_banana {
		$self->got_bananas or BananaError->throw(
			origin  => $self,
			message => "We have no bananas today!",
		);
	}
	
	after lose_bananas {
		$self->screech("Oh no!");
	}

	method screech (@strings) {
		my $name = $self->name;
		say "$name: $_" for @strings;
	}	
}

class Monkey::Loud extends Monkey
{
	preprocess screech (@strings) {
		return map { uc($_) } @strings;
	}
}

try {
	my $bobo = Monkey::Loud->new;
	$bobo->give_banana( Banana->new );
	$bobo->lose_bananas;
	$bobo->give_banana( Banana->new );
	$bobo->eat_banana;
	$bobo->eat_banana;
}
catch (BananaError $e) {
	warn sprintf("%s: %s\n", ref $e, $e->message);
}

