use Test::More tests => 4;
use MooseX::DeclareX
	plugins => [qw/ build singleton /];

class Local::Normal
{
	build identifier returns (Int) { int rand 1_000_000_000 }
}

class Local::Single
	extends Local::Normal
	is singleton;

ok(
	Local::Single::->new->DOES('MooseX::Singleton::Role::Object')
);

ok not(
	Local::Normal::->new->DOES('MooseX::Singleton::Role::Object')
);

is(
	Local::Single::->new->identifier,
	Local::Single::->new->identifier,
);

is(
	Local::Single::->instance->identifier,
	Local::Single::->instance->identifier,
);

