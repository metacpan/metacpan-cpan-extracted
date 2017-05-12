use Test::More tests => 3;
use MooseX::DeclareX plugins => [qw(build)];

class Monkey
{
	build name { 'Anon' }
	build age returns (Num) { 1 }
	
	method screech ($sound) {
		return $self->name, q[: ], $sound;
	}
}

is(
	Monkey->new(name => 'Bob')->name,
	'Bob',
);

is(
	Monkey->new->name,
	'Anon',
);

is(
	Monkey->meta->get_attribute('age')->type_constraint->name,
	'Num',
);
