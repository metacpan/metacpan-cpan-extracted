use Test::Most;
use Data::Printer { deparse => 1 };
use String::CamelSnakeKebab qw/:all/;

my %tests = (
    'FluxCapacitor'          => sub { upper_camel_case 'flux-capacitor'         },
    'fluxCapacitor'          => sub { lower_camel_case 'flux-capacitor'         },
    'a_snake_slithers_slyly' => sub { lower_snake_case 'ASnakeSlithersSlyly'    },
    'address1'               => sub { lower_snake_case 'address1'               },
    'A_Snake_Slithers_Slyly' => sub { upper_snake_case 'ASnakeSlithersSlyly'    },
    'I_AM_CONSTANT'          => sub { constant_case    'I am constant'          },
    'peppers-meat-pineapple' => sub { kebab_case       'Peppers_Meat_Pineapple' },
    'X-SSL-Cipher'           => sub { http_header_case 'x-ssl-cipher'           },
);

while ( my ($expected_answer, $test_this) = each %tests ) {

    cmp_deeply 
        $test_this->(),
        $expected_answer, 
        "got <$expected_answer> from \n" . p($test_this);

}

{
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++ };
    is( lower_snake_case(''), '', 'empty string unchanged' );
    is( $warnings, 0, 'empty string causes no warnings' );
}

done_testing;
