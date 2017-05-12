use Test::More tests => 6;
use Object::Stash;

{
	package Local::TestClass;
	use Object::Stash -type => 'object';
	sub new {bless[@_],shift}
}

my $obj = Local::TestClass->new;

is(
	ref $obj->stash,
	'Local::TestClass::stash'
	);

$obj->stash(foo => 'bar');

is(
	$obj->stash->{foo},
	'bar'
	);

is(
	$obj->stash->foo,
	'bar'
	);

$obj->stash->foo = 'baz';

is(
	$obj->stash->{foo},
	'baz'
	);

$obj->stash->foo('quux');

is(
	$obj->stash->{foo},
	'quux'
	);

$obj->stash->foo++;

is(
	$obj->stash->foo,
	'quuy'
	);
