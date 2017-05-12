use strict;
use warnings;

use Test::More; 

use Term::Caca;

my %list = Term::Caca->driver_list;

ok scalar(%list), 'driver_list()';

my @drivers = Term::Caca->drivers;

ok scalar( @drivers ), 'drivers()';

eval {
    my $term = Term::Caca->new( driver => 'nullo' );
};
ok $@, 'creating with a bad driver';

if ( grep { /^null$/ } @drivers ) {
    my $term = Term::Caca->new( driver => 'null' );
    pass 'creating with the null driver';
}

done_testing();
