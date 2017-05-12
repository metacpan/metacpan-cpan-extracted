package Example::Construction::Counter_v4;

use Minions
    interface => [ qw( next ) ],

    construct_with => {
        start => {
            assert => {
                is_integer => sub { $_[0] =~ /^\d+$/ }
            },
        },
    },
    implementation => 'Example::Construction::Acme::Counter_v2';

1;
