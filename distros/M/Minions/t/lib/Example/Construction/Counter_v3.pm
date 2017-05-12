package Example::Construction::Counter_v3;

use strict;
use Minions
    interface => [ qw( next ) ],

    construct_with => {
        start => {
            assert => {
                is_integer => sub { $_[0] =~ /^\d+$/ }
            },
        },
    },
    class_methods => {
        new => sub {
            my ($class, $start) = @_;

            my $util = Minions::utility_class($class);
            $util->assert(start => $start);
            my $obj = $util->new_object({count => $start});
            return $obj;
        },
    },

    implementation => 'Example::Construction::Acme::Counter';

1;
