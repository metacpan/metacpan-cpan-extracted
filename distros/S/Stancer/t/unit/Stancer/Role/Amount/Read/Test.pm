package Stancer::Role::Amount::Read::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Role::Amount::Read::Stub;
use TestCase;

## no critic (ProhibitPunctuationVars, RequireExtendedFormatting, RequireFinalReturn)

sub amount : Tests(2) {
    my $object = Stancer::Role::Amount::Read::Stub->new();
    my $amount = random_integer(50, 9999);

    is($object->amount, undef, 'Undefined by default');

    throws_ok { $object->amount(random_integer(50, 99_999)) } qr/amount is a read-only accessor/sm, 'Not writable';
}

sub currency : Tests(2) {
    my $object = Stancer::Role::Amount::Read::Stub->new();

    is($object->currency, undef, 'Undefined by default');

    throws_ok { $object->currency(random_string(3)) } qr/currency is a read-only accessor/sm, 'Not writable';
}

1;
