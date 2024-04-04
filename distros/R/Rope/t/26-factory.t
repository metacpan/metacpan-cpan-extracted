use Test::More;

{
	package Custom;

	use Rope;
	use Rope::Autoload;
	use Rope::Factory qw/Str HashRef ArrayRef/;

	factory one => (
		[Str] => sub {
			return 'string';
		},
		[Str, Str] => sub {
			return 'string string';
		},		
		[Str, HashRef, ArrayRef] => sub {
			return 'string hashref arrayref'
		}
	);

	factory one => (
		[Str, Str, Str] => sub {
			return 'string string string';
		}
	);

	1;
}

{
	package Extendings;

	use Rope;
	extends 'Custom';
}

my $c = Custom->new();

is($c->{one}('abc'), 'string');

is($c->{one}('abc', 'def'), 'string string');

is($c->one('str', { a => 1 }, [qw/1 2 3/]), 'string hashref arrayref');

$c->one('str', 'str', 'str');

is($c->one('str', 'str', 'str'), 'string string string');

$c = Extendings->new();

is($c->{one}('abc'), 'string');

is($c->{one}('abc', 'def'), 'string string');

is($c->one('str', { a => 1 }, [qw/1 2 3/]), 'string hashref arrayref');

$c->one('str', 'str', 'str');

#is($c->one('str', 'str', 'str'), 'string string string');

ok(1);

done_testing();
