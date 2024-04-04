package Stancer::Core::Iterator::Payment::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Core::Iterator::Payment;
use TestCase;

## no critic (RequireFinalReturn)

sub instanciate : Tests(2) {
    my $object = Stancer::Core::Iterator::Payment->new();

    isa_ok($object, 'Stancer::Core::Iterator::Payment', 'Stancer::Core::Iterator::Payment->new()');
    isa_ok($object, 'Stancer::Core::Iterator', 'Stancer::Core::Iterator::Payment->new()');
}

1;
