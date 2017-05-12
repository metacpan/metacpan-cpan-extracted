package Example::Construction::Counter_v2;

use strict;
use Minions ();

our %__meta__ = (
    interface => [ qw( next ) ],

    construct_with => {
        start => {
            assert => {
                is_integer => sub { $_[0] =~ /^\d+$/ }
            },
        },
    },
    implementation => 'Example::Construction::Acme::Counter',
);

sub new {
    my ($class, $start) = @_;

    my $util = Minions::utility_class($class);
    $util->assert(start => $start);
    my $obj = $util->new_object({count => $start});
    return $obj;
}

Minions->minionize;
