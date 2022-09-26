use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

package My::JSON; {
	use Class::Tiny;
	use Sub::MultiMethod qw(multimethod);
	use Types::Standard -types;
	
	multimethod stringify => (
		positional => [ Undef ],
		code       => sub {
			my ($self, $undef) = (shift, @_);
			'null';
		},
	);
	
	multimethod stringify => (
		positional => [ ScalarRef[Bool] ],
		code       => sub {
			my ($self, $bool) = (shift, @_);
			$$bool ? 'true' : 'false';
		},
	);
	
	multimethod stringify => (
		alias      => "stringify_str",
		positional => [ Str ],
		code       => sub {
			my ($self, $str) = (shift, @_);
			sprintf(q<"%s">, quotemeta($str));
		},
	);
	
	multimethod stringify => (
		positional => [ Num ],
		code       => sub {
			my ($self, $n) = (shift, @_);
			$n;
		},
	);
	
	multimethod stringify => (
		positional => [ ArrayRef ],
		code       => sub {
			my ($self, $arr) = (shift, @_);
			sprintf(
				q<[%s]>,
				join(q<,>, map($self->stringify($_), @$arr))
			);
		},
	);
	
	multimethod stringify => (
		positional => [ HashRef ],
		code       => sub {
			my ($self, $hash) = (shift, @_);
			sprintf(
				q<{%s}>,
				join(
					q<,>,
					map sprintf(
						q<%s:%s>,
						$self->stringify_str($_),
						$self->stringify($hash->{$_})
					), sort keys %$hash,
				)
			);
		},
	);
}

package main;

my $json = My::JSON->new;

my $str = $json->stringify({
	foo => 123,
	bar => [1,2,3],
	baz => \1,
	quux => { xyzzy => 666 },
});

is($str, '{"bar":[1,2,3],"baz":true,"foo":123,"quux":{"xyzzy":666}}');

is(
	$json->stringify(\[]),
	'true',
	'coercion',
);

like(
	exception { $json->stringify(qr//) },
	qr/multi.?method/i,
);

done_testing;