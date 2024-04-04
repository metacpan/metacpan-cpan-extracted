package Stancer::Refund::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use TestCase qw(:lwp); # Must be called first to initialize logs
use DateTime;
use Stancer::Refund;

## no critic (RequireExtendedFormatting, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub instanciate : Tests(8) {
    {
        my $object = Stancer::Refund->new();

        isa_ok($object, 'Stancer::Refund', 'Stancer::Refund->new()');
        isa_ok($object, 'Stancer::Core::Object', 'Stancer::Refund->new()');

        ok($object->does('Stancer::Role::Amount::Write'), 'Should use Stancer::Role::Amount::Write');
    }

    {
        my $id = random_string(29);
        my $amount = random_integer(50, 9999);
        my $payment = Stancer::Payment->new();

        my $object = Stancer::Refund->new(
            id => $id,
            amount => $amount,
            payment => $payment,
        );

        isa_ok($object, 'Stancer::Refund', 'Stancer::Refund->new(foo => "bar")');

        is($object->id, $id, 'Should add a value for `id` property');

        is($object->amount, $amount, 'Should have a value for `amount` property');
        is($object->payment, $payment, 'Should have a value for `payment` property');

        my $exported = {
            amount => $amount,
            payment => {},
        };

        cmp_deeply_json($object, $exported, 'They should be exported');
    }
}

sub date_bank : Tests(5) {
    my $object = Stancer::Refund->new();
    my $date = random_integer(1_500_000_000, 1_600_000_000);

    my $config = Stancer::Config->init();
    my $delta = random_integer(1, 6);
    my $tz = DateTime::TimeZone->new(name => sprintf '+%04d', $delta * 100);

    $config->default_timezone($tz);

    is($object->date_bank, undef, 'Undefined by default');

    throws_ok { $object->date_bank($date) } qr/date_bank is a read-only accessor/sm, 'Not writable';

    $object->hydrate(date_bank => $date);

    isa_ok($object->date_bank, 'DateTime', '$object->date_bank');
    is($object->date_bank->epoch, $date, 'Date is correct');
    is($object->date_bank->time_zone, $tz, 'Should have the same timezone now');
}

sub date_refund : Tests(5) {
    my $object = Stancer::Refund->new();
    my $date = random_integer(1_500_000_000, 1_600_000_000);

    my $config = Stancer::Config->init();
    my $delta = random_integer(1, 6);
    my $tz = DateTime::TimeZone->new(name => sprintf '+%04d', $delta * 100);

    $config->default_timezone($tz);

    is($object->date_refund, undef, 'Undefined by default');

    throws_ok { $object->date_refund($date) } qr/date_refund is a read-only accessor/sm, 'Not writable';

    $object->hydrate(date_refund => $date);

    isa_ok($object->date_refund, 'DateTime', '$object->date_refund');
    is($object->date_refund->epoch, $date, 'Date is correct');
    is($object->date_refund->time_zone, $tz, 'Should have the same timezone now');
}

sub endpoint : Test {
    my $object = Stancer::Refund->new();

    is($object->endpoint, 'refunds');
}

sub payment : Tests(3) {
    my $object = Stancer::Refund->new();
    my $payment = Stancer::Payment->new();

    is($object->payment, undef, 'Undefined by default');

    $object->payment($payment);

    is($object->payment, $payment, 'Should be updated');
    cmp_deeply_json($object, { payment => {} }, 'Should be exported');
}

sub status : Tests(3) {
    my $object = Stancer::Refund->new();
    my $status = random_string(10);

    is($object->status, undef, 'Undefined by default');

    $object->hydrate(status => $status);

    is($object->status, $status, 'Should have a value');

    throws_ok { $object->status($status) } qr/status is a read-only accessor/sm, 'Not writable';
}

1;
