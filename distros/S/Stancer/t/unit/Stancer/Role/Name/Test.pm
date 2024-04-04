package Stancer::Role::Name::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Role::Name::Stub;
use TestCase;

## no critic (RequireExtendedFormatting, RequireFinalReturn)

sub name : Tests(3) {
    my $object = Stancer::Role::Name::Stub->new();
    my $name = random_string(64);

    is($object->name, undef, 'Undefined by default');

    $object->name($name);

    is($object->name, $name, 'Should be updated');
    cmp_deeply_json($object, { name => $name }, 'Should be exported');
}

1;
