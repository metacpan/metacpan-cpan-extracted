use Test::More;

{
    package One::Two;

    use Moo;
    with 'MooX::VariantAttribute::Role';

    has '+variant_last_value' => (
		default => sub { 
			return {
				refs => {
                	find => 'ARRAY',
					set => 'refs returned - ARRAY - one,two'
                },
                parser => {
                    set => bless( {}, 'Random::Parser::Two' ),
                    find => 'Random::Parser::Two'
                }
        	}; 
		}
    );

}

my $obj = One::Two->new;

is $obj->_variant_last_value('refs', 'find', 'ARRAY'), 1, "YES we can find ARRAY";
is $obj->_variant_last_value('refs', 'set', 'refs returned - ARRAY - one,two'), 1, "YES we can find ARRAY";
is $obj->_variant_last_value('refs', 'find', 'ARRY'), undef, "No we can't find ARRY";
is $obj->_variant_last_value('refs', 'set', 'refs returned - ARRY - one,two'), undef, "NO we can't find ARRY";

is $obj->_variant_last_value('parser', 'find', 'Random::Parser::Two'), 1, 'Yes we can find Random::Parser::Two';

done_testing();
