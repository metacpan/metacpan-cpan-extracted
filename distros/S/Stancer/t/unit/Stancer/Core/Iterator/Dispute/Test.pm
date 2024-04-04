package Stancer::Core::Iterator::Dispute::Test;
use base qw(Test::Class);

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Core::Iterator::Dispute;
use TestCase;

## no critic (RequireFinalReturn)

sub instanciate : Tests(2) {
    my $object = Stancer::Core::Iterator::Dispute->new();

    isa_ok($object, 'Stancer::Core::Iterator::Dispute', 'Stancer::Core::Iterator::Dispute->new()');
    isa_ok($object, 'Stancer::Core::Iterator', 'Stancer::Core::Iterator::Dispute->new()');
}

sub test_create_element : Tests(4) {
    my $id = random_string(29);
    my $obj;

    $obj = Stancer::Core::Iterator::Dispute->_create_element(); ## no critic (ProtectPrivateSubs)

    isa_ok($obj, 'Stancer::Dispute', 'Should return an instance of dispute');
    is($obj->id, undef, 'Should not have an id');

    $obj = Stancer::Core::Iterator::Dispute->_create_element($id); ## no critic (ProtectPrivateSubs)

    isa_ok($obj, 'Stancer::Dispute', 'Should return an instance of dispute');
    is($obj->id, $id, 'Should have an id');
}

1;
