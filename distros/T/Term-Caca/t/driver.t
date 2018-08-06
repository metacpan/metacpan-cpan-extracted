use strict;
use warnings;

use Test::More; 
use Test::Exception;

use Term::Caca;

use experimental 'signatures', 'postderef';

my %list = Term::Caca->driver_list->%*;

ok scalar(%list), 'driver_list()';

my @drivers = Term::Caca->drivers;

ok scalar( @drivers ), 'drivers()';

dies_ok {
     Term::Caca->new( driver => 'nullo' )->display;
} 'creating with a bad driver';

lives_ok {
    Term::Caca->new( driver => 'null' );
} 'creating with the null driver';

done_testing();
