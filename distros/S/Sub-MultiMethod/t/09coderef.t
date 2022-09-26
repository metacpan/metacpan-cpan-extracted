use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Sub::MultiMethod qw(multimethod);
use Types::Standard -types;

my ($stringify, $stringify_str);

multimethod \$stringify => (
	method     => 0,
	positional => [ Undef ],
	code       => sub {
		my ($undef) = (@_);
		'null';
	},
);

multimethod \$stringify => (
	method     => 0,
	positional => [ ScalarRef[Bool] ],
	code       => sub {
		my ($bool) = (@_);
		$$bool ? 'true' : 'false';
	},
);

multimethod \$stringify => (
	method     => 0,
	alias      => \$stringify_str,
	positional => [ Str ],
	code       => sub {
		my ($str) = (@_);
		sprintf(q<"%s">, quotemeta($str));
	},
);

multimethod \$stringify => (
	method     => 0,
	positional => [ Num ],
	code       => sub {
		my ($n) = (@_);
		$n;
	},
);

{ package Local::Xyzzy;
use Sub::MultiMethod 'multimethod';
multimethod \$stringify => (
	method     => 0,
	positional => [ ::ArrayRef ],
	code       => sub {
		my ($arr) = (@_);
		sprintf(
			q<[%s]>,
			join(q<,>, map($stringify->($_), @$arr))
		);
	},
);
}

multimethod \$stringify => (
	method     => 0,
	positional => [ HashRef ],
	code       => sub {
		my ($hash) = (@_);
		sprintf(
			q<{%s}>,
			join(
				q<,>,
				map sprintf(
					q<%s:%s>,
					$stringify_str->($_),
					$stringify->($hash->{$_})
				), sort keys %$hash,
			)
		);
	},
);

my $str = $stringify->({
	foo => 123,
	bar => [1,2,3],
	baz => \1,
	quux => { xyzzy => 666 },
});

is($str, '{"bar":[1,2,3],"baz":true,"foo":123,"quux":{"xyzzy":666}}');

is(
	$stringify->(\[]),
	'true',
	'coercion',
);

like(
	exception { $stringify->(qr//) },
	qr/multi.?method/i,
);

undef $stringify;

is_deeply(
	Sub::MultiMethod->_get_multimethods_ref(__PACKAGE__),
	{},
	'No trace left behind after $stringify goes out of scope',
);

is(
	$stringify_str->("a"),
	'"a"',
	'$stringify_str still works as it does not use the dispatcher',
);

undef $stringify_str;

done_testing;
