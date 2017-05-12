use Test::More tests => 5;
use MooseX::DeclareX plugins => [qw(abstract)];

class Primate is abstract
{
	requires 'classification';
	has 'name' => (is => 'ro', isa => 'Str');
}

class Monkey is concrete extends Primate
{
	has 'classification' => (is => 'ro', isa => 'Str');
}

try {
	class Human extends Primate;
}
catch {
	pass("can't inherit from abstract class without implementing required method");
}

my $bobo = Monkey::->new(name => 'Bobo');
is(
	$bobo->name,
	'Bobo',
	"can instantiate derived classes",
);

try {
	my $popo = Primate::->new;
}
catch ($e) {
	like($e, qr(^Primate is abstract), "can't instantiate abstract classes");
}

try {
	class Baboon is mutable extends Primate;
	pass("inherit from abstract class - mutable");
}

try {
	class Ape is abstract extends Primate;
	pass("inherit from abstract class - abstract");
}
