package Stancer::Sepa::Check::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use TestCase qw(:lwp); # Must be called first to initialize logs
use Stancer::Sepa::Check;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars, RequireExtendedFormatting)

sub instanciate : Tests(2) {
    { # 2 tests
        my $object = Stancer::Sepa::Check->new();

        isa_ok($object, 'Stancer::Sepa::Check', 'Stancer::Sepa::Check->new()');
        isa_ok($object, 'Stancer::Core::Object', 'Stancer::Sepa::Check->new()');
    }
}

sub date_birth : Tests(4) {
    my $object = Stancer::Sepa::Check->new();

    is($object->date_birth, undef, 'Undefined by default');

    $object->hydrate(date_birth => $true);

    ok($object->date_birth, 'Should be true');

    $object->hydrate(date_birth => $false);

    ok(not($object->date_birth), 'Should be false');

    throws_ok { $object->date_birth($true) } qr/date_birth is a read-only accessor/sm, 'Not writable';
}

sub endpoint : Test {
    my $object = Stancer::Sepa::Check->new();

    is($object->endpoint, 'sepa/check');
}

sub response : Tests(3) {
    my $object = Stancer::Sepa::Check->new();
    my $response = random_string(2);

    is($object->response, undef, 'Undefined by default');

    $object->hydrate(response => $response);

    is($object->response, $response, 'Should have a value');

    throws_ok { $object->response($response) } qr/response is a read-only accessor/sm, 'Not writable';
}

sub sepa : Tests(5) {
    { # 3 tests
        note 'With an id';

        my $id = random_string(29);
        my $object = Stancer::Sepa::Check->new($id);

        isa_ok($object->sepa, 'Stancer::Sepa', 'Stancer::Sepa::Check->new($id)');
        is($object->sepa->id, $id, 'Should have the same id');

        throws_ok { $object->sepa($id) } qr/sepa is a read-only accessor/sm, 'Not writable';
    }

    { # 2 tests
        note 'Without an id';

        my $object = Stancer::Sepa::Check->new();

        is($object->sepa, undef, 'Should be undefined');

        throws_ok { $object->sepa(random_string(29)) } qr/sepa is a read-only accessor/sm, 'Not writable';
    }
}

sub score_name : Tests(3) {
    my $object = Stancer::Sepa::Check->new();
    my $score_name = random_integer(0, 100);

    is($object->score_name, undef, 'Undefined by default');

    $object->hydrate(score_name => $score_name);

    is($object->score_name, $score_name / 100, 'Should have a value');

    throws_ok { $object->score_name($score_name) } qr/score_name is a read-only accessor/sm, 'Not writable';
}

sub status : Tests(3) {
    my $object = Stancer::Sepa::Check->new();
    my $status = random_string(10);

    is($object->status, undef, 'Undefined by default');

    $object->hydrate(status => $status);

    is($object->status, $status, 'Should have a value');

    throws_ok { $object->status($status) } qr/status is a read-only accessor/sm, 'Not writable';
}

sub TO_JSON : Tests(6) {
    { # 2 tests
        note 'SEPA without ID';

        my $bic = bic_provider();
        my $date_birth = random_date(1950, 2000);
        my $date_mandate = random_integer(1_500_000_000, 1_600_000_000);
        my @ibans = iban_provider();
        my $mandate = random_string(34);
        my $name = random_string(64);

        my $sepa = Stancer::Sepa->new(
            bic => $bic,
            date_birth => $date_birth,
            date_mandate => $date_mandate,
            iban => $ibans[0],
            mandate => $mandate,
            name => $name,
        );
        my $check = Stancer::Sepa::Check->new(sepa => $sepa);

        eq_or_diff(ref $check->TO_JSON(), 'HASH', 'TO_JSON should return an HASH');
        eq_or_diff($check->TO_JSON(), $sepa->TO_JSON(), 'Should return SEPA data');
    }

    { # 2 tests
        note 'SEPA with ID';

        my $id = random_string(29);
        my $bic = bic_provider();
        my $date_birth = random_date(1950, 2000);
        my $date_mandate = random_integer(1_500_000_000, 1_600_000_000);
        my @ibans = iban_provider();
        my $mandate = random_string(34);
        my $name = random_string(64);

        my $sepa = Stancer::Sepa->new(
            id => $id,
            bic => $bic,
            date_birth => $date_birth,
            date_mandate => $date_mandate,
            iban => $ibans[0],
            mandate => $mandate,
            name => $name,
        );
        my $check = Stancer::Sepa::Check->new(sepa => $sepa);

        eq_or_diff(ref $check->TO_JSON(), 'HASH', 'TO_JSON should return an HASH');
        eq_or_diff($check->TO_JSON(), { id => $id }, 'Should return only SEPA ID');
    }

    { # 2 tests
        note 'Without SEPA';

        my $check = Stancer::Sepa::Check->new();

        eq_or_diff(ref $check->TO_JSON(), 'HASH', 'TO_JSON should return an HASH');
        eq_or_diff($check->TO_JSON(), {}, 'Should be empty');
    }
}

1;
