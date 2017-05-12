use strict;
use warnings;

use Test::More tests => 1;

use Test::Exception;

use Pollux::Action;

my $action = Pollux::Action->new('foo')->();

dies_ok {
    $action->{bar} = 'stuff'
} "can't modify a key";



