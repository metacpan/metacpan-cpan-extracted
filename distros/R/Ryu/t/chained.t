use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

use Ryu;

is(exception {
    my $chained = Ryu::Source->chained;
    isa_ok($chained, 'Ryu::Source');
    is($chained->label, 'unknown', 'starts off with "unknown" label');
    is($chained->parent, undef, 'has no parent');
}, undef, 'can create ->chained source without issues');

done_testing;


