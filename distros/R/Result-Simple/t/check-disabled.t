=pod

Test the Result::Simple module with CHECK_ENABLED is falsy.
These tests are same cases as Result-Simple.t, but CHECK_ENABLED is falsy.

=cut

use Test2::V0 qw(subtest is like unlike lives dies note done_testing);
use Test2::V0 ok => { -as => 'test_ok' };

use lib "t/lib";
use TestType qw( Int NonEmptyStr );

BEGIN {
    $ENV{RESULT_SIMPLE_CHECK_ENABLED} = 0;
}

use Result::Simple qw( ok err result_for );

subtest 'Test `ok` and `err` functions' => sub {
    subtest '`ok` and `err` functions just return values' => sub {
        my ($data, $err) = ok('foo');
        is $data, 'foo';
        is $err, undef;

        ($data, $err) = err('bar');
        is $data, undef;
        is $err, 'bar';
    };

    subtest '`ok` and `err` must be called in list context, but when CHECK_ENABLED is falsy, then do not throw exception' => sub {
        test_ok lives { my $data = ok('foo') };
        test_ok lives { my $err = err('bar') };
    };

    subtest '`err` does not allow falsy values, but when CHECK_ENABLED is falsy, then do not throw exception' => sub {
        test_ok lives { my ($data, $err) = err() };
        test_ok lives { my ($data, $err) = err(0) };
        test_ok lives { my ($data, $err) = err('0') };
        test_ok lives { my ($data, $err) = err('') };
    };
};

subtest 'Test `result_for` function' => sub {

    result_for valid => Int, NonEmptyStr;
    sub valid { ok(42) }

    result_for invalid_ok_type => Int, NonEmptyStr;
    sub invalid_ok_type { ok('foo') }

    result_for invalid_err_type => Int, NonEmptyStr;
    sub invalid_err_type { err(\1) }

    subtest 'When a return value satisfies the Result type (T, E), then return the value' => sub {
        my ($data, $err) = valid();
        is $data, 42;
        is $err, undef;
    };

    subtest 'When a return value does not satisfy the Result type (T, E), then throw a exception, but CHECK_ENABLED is falsy, then do not' => sub {
        test_ok lives { my ($data, $err) = invalid_ok_type() };
        test_ok lives { my ($data, $err) = invalid_err_type() };
    };

    subtest 'Must handle error, but CHECK_ENABLED is falsy, then do not throw exception' => sub {
        test_ok lives { my $result = valid() };
    };

    subtest 'Result(T, E) requires `check` method, but CHECK_ENABLED is falsy, then do not throw exception' => sub {
        sub invalid_type_T { ok(42) };
        test_ok lives { result_for invalid_type_T => 'Hello', NonEmptyStr };

        sub invalid_type_E { err(42) };
        test_ok lives { result_for invalid_type_E => Int, 'World' };
    };

    subtest 'E should not allow falsy values, but CHECK_ENABLED is falsy, then do not throw exception' => sub {
        sub should_not_allow_falsy { err(0) };
        test_ok lives { result_for should_not_allow_falsy => Int, Int };
    };

    subtest 'Test the details of `retsult_for` function' => sub {
        # 'When CHECK_ENABLED is falsy, then do not wrap the original function';

        subtest 'stacktrace' => sub {
            result_for test_stacktrace => Int, NonEmptyStr;
            sub test_stacktrace { Carp::confess('hello') }

            my $error = dies { my ($data, $err) = test_stacktrace() };
            my @errors = split /\n/, $error;

            my $file = __FILE__;
            my $line = __LINE__;

            like $errors[0], qr!hello at $file line @{[$line - 6]}!;
            like $errors[1], qr!test_stacktrace\(\) called at $file line @{[$line - 4]}!, 'stacktrace includes function name';
            unlike $error, qr!Result/Simple.pm!, 'stacktrace does not include Result::Simple';
            note $errors[0];
            note $errors[1];
        };

        subtest 'Same subname and prototype as original' => sub {

            result_for same => Int, NonEmptyStr;
            sub same (;$) { ok(42) }

            my $code = \&same;

            require Sub::Util;
            my $name = Sub::Util::subname($code);
            is $name, 'main::same';

            my $proto = Sub::Util::prototype($code);
            is $proto, ';$';
        };
    };
};

done_testing;
