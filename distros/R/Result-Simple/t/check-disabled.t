=pod

Test the Result::Simple module with CHECK_ENABLED is falsy.
These tests are same cases as Result-Simple.t, but CHECK_ENABLED is falsy.

=cut

use Test2::V0;

use lib "t/lib";
use TestType qw( Int NonEmptyStr );

BEGIN {
    # Default is falsy
    # $ENV{RESULT_SIMPLE_CHECK_ENABLED} = 0;
}

use Result::Simple;

subtest 'Test `Ok` and `Err` functions' => sub {
    subtest '`Ok` and `Err` functions just return values' => sub {
        my ($data, $err) = Ok('foo');
        is $data, 'foo';
        is $err, undef;

        ($data, $err) = Err('bar');
        is $data, undef;
        is $err, 'bar';
    };

    subtest '`Ok` and `Err` must be called in list context, but when CHECK_ENABLED is falsy, then do not throw exception' => sub {
        ok lives { my $data = Ok('foo') };
        ok lives { my $err = Err('bar') };
    };

    subtest '`Err` does not allow falsy values, but when CHECK_ENABLED is falsy, then do not throw exception' => sub {
        ok lives { my ($data, $err) = Err() };
        ok lives { my ($data, $err) = Err(0) };
        ok lives { my ($data, $err) = Err('0') };
        ok lives { my ($data, $err) = Err('') };
    };
};

subtest 'Test :Result attribute' => sub {
    sub valid : Result(Int, NonEmptyStr) { Ok(42) }
    sub invalid_ok_type :Result(Int, NonEmptyStr) { Ok('foo') }
    sub invalid_err_type :Result(Int, NonEmptyStr) { Err(\1) }

    subtest 'When a return value satisfies the Result type (T, E), then return the value' => sub {
        my ($data, $err) = valid();
        is $data, 42;
        is $err, undef;
    };

    subtest 'When a return value does not satisfy the Result type (T, E), then throw a exception, but CHECK_ENABLED is falsy, then do not' => sub {
        ok lives { my ($data, $err) = invalid_ok_type() };
        ok lives { my ($data, $err) = invalid_err_type() };
    };

    subtest 'Must handle error, but CHECK_ENABLED is falsy, then do not throw exception' => sub {
        ok lives { my $result = valid() };
    };

    subtest 'Result(T, E) requires `check` method, but CHECK_ENABLED is falsy, then do not throw exception' => sub {
        eval "sub invalid_type_T :Result('HELLO', NonEmptyStr) { Ok('HELLO') }";
        is $@, '';

        eval "sub invalid_type_E :Result(Int, 'WORLD') { Err('WORLD') }";
        is $@, '';
    };

    subtest 'E should not allow falsy values, but CHECK_ENABLED is falsy, then do not throw exception' => sub {
        eval "sub should_not_allow_falsy :Result(Int, Int) { }";
        is $@, '';
    };
};

subtest 'Test the details of :Result attribute' => sub {
    note 'When CHECK_ENABLED is falsy, then do not wrap the original function';

    subtest 'Useful stacktrace' => sub {
        sub test_stacktrace :Result(Int, NonEmptyStr) { Carp::confess('hello') }

        eval { my ($data, $err) = test_stacktrace() };

        my $file = __FILE__;
        like $@, qr!hello at $file line!;
        like $@, qr/main::test_stacktrace\(\) called at $file line /, 'stacktrace includes function name';
        unlike $@, qr/Result::Simple::/, 'stacktrace does not include Result::Simple by Scope::Upper';
    };

    subtest 'Same subname and prototype as original' => sub {
        sub same (;$) :Result(Int, NonEmptyStr) { Ok(42) }

        my $code = \&same;

        require Sub::Util;
        my $name = Sub::Util::subname($code);
        is $name, 'main::same';

        my $proto = Sub::Util::prototype($code);
        is $proto, ';$';
    };
};

done_testing;
