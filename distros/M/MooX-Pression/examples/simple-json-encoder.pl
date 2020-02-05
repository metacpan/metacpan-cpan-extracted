use v5.18;
use strict;
use warnings;

my $json = MyApp->new_json_encoder;

say $json->stringify({
	foo  => 123,
	bar  => [1,2,3],
	baz  => \1,
	quux => { xyzzy => 666 },
});

package MyApp {
	use MooX::Pression;
	
	# A JSON encoder.
	class JSON::Encoder {
		multi method stringify (Undef $value) {
			'null';
		}
		
		multi method stringify (ScalarRef[Bool] $value) {
			$$value ? 'true' : 'false';
		}
		
		multi method stringify (Num $value) {
			$value;
		}
		
		# does not strictly follow JSON specs
		multi method stringify :alias(quote_str) (Str $value)  {
			sprintf(q<"%s">, quotemeta $value);
		}
		
		multi method stringify (ArrayRef $arr) {
			sprintf(
				q<[%s]>,
				join(q<,>, map($self->stringify($_), @$arr))
			);
		}
		
		multi method stringify (HashRef $hash) {
			sprintf(
				q<{%s}>,
				join(
					q<,>,
					map sprintf(
						q<%s:%s>,
						$self->quote_str($_),
						$self->stringify($hash->{$_}),
					), sort keys %$hash
				),
			);
		}
	}
}
