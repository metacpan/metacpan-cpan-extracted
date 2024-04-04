package Stancer::Core::Types::Helper::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Config; # Could not be loaded in Types::Helper
use Stancer::Core::Object::Stub;
use Stancer::Core::Types::Helper qw(coerce_boolean coerce_date coerce_datetime coerce_instance error_message);
use TestCase;

## no critic (RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub boolean : Tests(6) {
    my $coerce = coerce_boolean();

    is(ref $coerce, 'CODE', 'Should return a subroutine');

    is($coerce->(), undef, 'coerce_boolean()->() => undefined');

    ok($coerce->(1), 'coerce_boolean()->(1) => true');
    ok(not($coerce->(0)), 'coerce_boolean()->(0) => false');

    ok($coerce->('true'), 'coerce_boolean()->(\'true\') => true');
    ok(not($coerce->('false')), 'coerce_boolean()->(\'false\') => false');
}

sub date : Tests(12) {
    my @parts = localtime;
    my $year = random_integer(15) + $parts[5] + 1901;
    my $month = random_integer(1, 12);
    my $day = random_integer(1, 25);
    my $hour = random_integer(24);
    my $minute = random_integer(59);
    my $second = random_integer(59);

    my $dt = DateTime->new(
        year => $year,
        month => $month,
        day => $day,
        hour => $hour,
        minute => $minute,
        second => $second,
    );

    my $coerce = coerce_date();
    my $data;

    is(ref $coerce, 'CODE', 'Should return a subroutine');

    is($coerce->(), undef, 'coerce_date()->() => undefined');

    $data = $coerce->($dt);

    isa_ok($data, 'DateTime', 'coerce_date()->(DateTime->new) => is a DateTime');
    is($data->ymd, $dt->ymd, 'coerce_date()->(DateTime->new) => has a correct date');
    is($data->hms, '00:00:00', 'coerce_date()->(DateTime->new) => has no time');

    $data = $coerce->($dt->ymd);

    isa_ok($data, 'DateTime', 'coerce_date()->(\'YYYY-MM-DD\') => is a DateTime');
    is($data->ymd, $dt->ymd, 'coerce_date()->(\'YYYY-MM-DD\') => has a correct date');
    is($data->hms, '00:00:00', 'coerce_date()->(\'YYYY-MM-DD\') => has no time');

    $data = $coerce->($dt->epoch);

    isa_ok($data, 'DateTime', 'coerce_date()->(\'YYYY-MM-DD\') => is a DateTime');
    is($data->ymd, $dt->ymd, 'coerce_date()->(\'YYYY-MM-DD\') => has a correct date');
    is($data->hms, '00:00:00', 'coerce_date()->(\'YYYY-MM-DD\') => has no time');

    ## no critic (ClassHierarchies::ProhibitOneArgBless)
    is($coerce->(bless {}), undef, 'coerce_date()->(Object->new) => undefined');
    ## use critic
}

sub datetime : Tests(9) {
    my @parts = localtime;
    my $year = random_integer(15) + $parts[5] + 1901;
    my $month = random_integer(1, 12);
    my $day = random_integer(1, 25);
    my $hour = random_integer(24);
    my $minute = random_integer(59);
    my $second = random_integer(59);

    my $dt = DateTime->new(
        year => $year,
        month => $month,
        day => $day,
        hour => $hour,
        minute => $minute,
        second => $second,
    );

    my $coerce = coerce_datetime();
    my $data;

    is(ref $coerce, 'CODE', 'Should return a subroutine');

    is($coerce->(), undef, 'coerce_datetime()->() => undefined');

    $data = $coerce->($dt);

    isa_ok($data, 'DateTime', 'coerce_datetime()->(DateTime->new) => is a DateTime');
    is($data->ymd, $dt->ymd, 'coerce_datetime()->(DateTime->new) => has a correct date');
    is($data->hms, $dt->hms, 'coerce_datetime()->(DateTime->new) => has no time');

    $data = $coerce->($dt->epoch);

    isa_ok($data, 'DateTime', 'coerce_datetime()->(\'YYYY-MM-DD\') => is a DateTime');
    is($data->ymd, $dt->ymd, 'coerce_datetime()->(\'YYYY-MM-DD\') => has a correct date');
    is($data->hms, $dt->hms, 'coerce_datetime()->(\'YYYY-MM-DD\') => has no time');

    ## no critic (ClassHierarchies::ProhibitOneArgBless)
    is($coerce->(bless {}), undef, 'coerce_datetime()->(Object->new) => undefined');
    ## use critic
}

sub instance : Tests(6) {
    my $coerce = coerce_instance('Stancer::Core::Object::Stub');
    my $obj_ok = Stancer::Core::Object::Stub->new();
    my $obj_nok = bless {}; ## no critic (ClassHierarchies::ProhibitOneArgBless)
    my $id = random_string(29);

    is(ref $coerce, 'CODE', 'Should return a subroutine');

    is($coerce->(), undef, 'coerce_instance(\'Stancer::Core::Object::Stub\')->() => undefined');

    isa_ok(
        $coerce->($obj_ok),
        'Stancer::Core::Object::Stub',
        'coerce_instance(\'Stancer::Core::Object::Stub\')->(Stancer::Core::Object::Stub->new())',
    );
    is(
        $coerce->($obj_nok),
        undef,
        'coerce_instance(\'Stancer::Core::Object::Stub\')->(Object->new())',
    );

    my $data = $coerce->($id);

    isa_ok(
        $data,
        'Stancer::Core::Object::Stub',
        'coerce_instance(\'Stancer::Core::Object::Stub\')->(\'foo\')',
    );
    is($data->id, $id, 'The instance is properly created');
}

sub message : Tests(6) {
    { # 2 tests
        note 'With string';

        my $arg = random_string(10);
        my $message = '%s';
        my $ret = error_message($message);

        is(ref $ret, 'CODE', 'Should return a subroutine');
        is($ret->($arg), q/"/ . $arg . q/"/, 'Should output the message with a string argument');
    }

    { # 2 tests
        note 'With undef';

        my $message = '%s';
        my $ret = error_message($message);

        is(ref $ret, 'CODE', 'Should return a subroutine');
        is($ret->(undef), 'undef', 'Should output the message with "undef" in it');
    }

    { # 2 tests
        note 'With multiple arguments';

        my $arg1 = random_string(10);
        my $arg2 = random_integer(10, 99);
        my $message = '%2$d %1$s';
        my $ret = error_message($message);

        is(ref $ret, 'CODE', 'Should return a subroutine');
        is($ret->($arg1, $arg2), $arg2 . q/ "/ . $arg1 . q/"/, 'Should output the message with first arg with quote');
    }
}

1;
