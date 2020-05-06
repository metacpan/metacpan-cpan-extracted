use Moonshine::Test qw/:all/;

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


moon_test(
	name => 'Check One::Two',
	build => {
		class => 'One::Two'
	},
	instructions => [
		{
			test  => 'true',
			func => '_variant_last_value',
			args_list => 1,
			args => ['refs', 'find', 'ARRAY'],
		},
		{
			test => 'true',
			func => '_variant_last_value',
			args_list => 1,
			args => ['refs', 'set', 'refs returned - ARRAY - one,two'],
		},
		{
			test  => 'undef',
			func => '_variant_last_value',
			args_list => 1,
			args => ['refs', 'find', 'ARRY'],
		},
		{
			test => 'undef',
			func => '_variant_last_value',
			args_list => 1,
			args => ['refs', 'set', 'refs returned - ARRY - one,two'],
		},
		{
			test => 'true',
			func => '_variant_last_value',
			args_list => 1,
			args => ['parser', 'find', 'Random::Parser::Two'],
		}
	]
);

sunrise(6, flexing);
