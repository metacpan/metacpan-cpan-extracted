use 5.010;
use MooseX::DeclareX
	plugins => [qw(build having abstract)],
	;

class Primate
	is abstract
{
	requires 'classification';
	has 'name' => (is => 'ro', isa => 'Str');
}

class Monkey
	extends Primate
{
	has 'classification' => (is => 'ro', isa => 'Str');
}

class Human extends Primate is mutable;

my $bobo = Monkey::->new(name => 'Bobo');
say $bobo->name;

my $popo = Primate::->new;
