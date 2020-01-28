use v5.12;
use strict;
use warnings;

package My::JSON {
	use Moo;
	use Sub::MultiMethod qw(multimethod);
	use Types::Standard -types;
	
	multimethod stringify => (
		signature => [ Undef ],
		code      => sub {
			my ($self, $undef) = (shift, @_);
			'null';
		},
	);
	
	multimethod stringify => (
		signature => [ ScalarRef[Bool] ],
		code      => sub {
			my ($self, $bool) = (shift, @_);
			$$bool ? 'true' : 'false';
		},
	);
	
	multimethod stringify => (
		alias     => "stringify_str",
		signature => [ Str ],
		code      => sub {
			my ($self, $str) = (shift, @_);
			sprintf(q<"%s">, quotemeta($str));
		},
	);
	
	multimethod stringify => (
		signature => [ Num ],
		code      => sub {
			my ($self, $n) = (shift, @_);
			$n;
		},
	);
	
	multimethod stringify => (
		signature => [ ArrayRef ],
		code      => sub {
			my ($self, $arr) = (shift, @_);
			sprintf(
				q<[%s]>,
				join(q<,>, map($self->stringify($_), @$arr))
			);
		},
	);
	
	multimethod stringify => (
		signature => [ HashRef ],
		code      => sub {
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

my $json = My::JSON->new;

say $json->stringify({
	foo => 123,
	bar => [1,2,3],
	baz => \1,
	quux => { xyzzy => 666 },
});
