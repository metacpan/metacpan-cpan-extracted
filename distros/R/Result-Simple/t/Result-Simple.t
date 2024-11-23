=pod

Test the Result::Simple module with CHECK_ENABLED is truthy.

=cut

use Test2::V0;

use lib "t/lib";
use TestType qw( Int NonEmptyStr );

BEGIN {
    $ENV{RESULT_SIMPLE_CHECK_ENABLED} = 1;
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

    subtest '`Ok` and `Err` must be called in list context' => sub {
        like dies { my $data = Ok('foo') }, qr/`Ok` must be called in list context/;
        like dies { my $err = Err('bar') }, qr/`Err` must be called in list context/;
    };

    subtest '`Ok` and `Err` does not allow multiple arguments' => sub {
        like dies { my ($data, $err) = Ok('foo', 'bar') }, qr/`Ok` does not allow multiple arguments/;
        like dies { my ($data, $err) = Err('bar', 'foo') }, qr/`Err` does not allow multiple arguments/;
    };

    subtest '`Ok` and `Err` does not allow no arguments' => sub {
        like dies { my ($data, $err) = Ok() }, qr/`Ok` does not allow no arguments/;
        like dies { my ($data, $err) = Err() }, qr/`Err` does not allow no arguments/;
    };

    subtest '`Err` does not allow falsy values' => sub {
        like dies { my ($data, $err) = Err(0) }, qr/`Err` does not allow a falsy value: 0/;
        like dies { my ($data, $err) = Err('0') }, qr/`Err` does not allow a falsy value: '0'/;
        like dies { my ($data, $err) = Err('') }, qr/`Err` does not allow a falsy value: ''/;
    };
};

subtest 'Test :Result attribute' => sub {
    # valid cases
    sub valid :Result(Int, NonEmptyStr) { Ok(42) }
    sub no_error :Result(Int, undef) { Ok(42) }

    # invalid cases
    sub invalid_ok_type :Result(Int, NonEmptyStr) { Ok('foo') }
    sub invalid_err_type :Result(Int, NonEmptyStr) { Err(\1) }
    sub a_few_result :Result(Int, NonEmptyStr) { 'foo' }
    sub too_many_result :Result(Int, NonEmptyStr) { (1,2,3) }
    sub never_return_error :Result(Int, undef) { Err('foo') }

    subtest 'When a return value satisfies the Result type (T, E), then return the value' => sub {
        my ($data, $err) = valid();
        is $data, 42;
        is $err, undef;
    };

    subtest 'When a return value satisfies the Result type (T, undef), then return the value' => sub {
        my ($data, $err) = no_error();
        is $data, 42;
        is $err, undef;
    };

    subtest 'When a return value does not satisfy the Result type (T, E), then throw a exception' => sub {
        like dies { my ($data, $err) = invalid_ok_type() },    qr!Invalid success result in `invalid_ok_type`: \['foo',undef\]!;
        like dies { my ($data, $err) = invalid_err_type() },   qr!Invalid failure result in `invalid_err_type`: \[undef,\\1\]!;
        like dies { my ($data, $err) = a_few_result() },       qr!Invalid result tuple \(T, E\) in `a_few_result`. Do you forget to call `Ok` or `Err` function\? Got: \['foo'\]!;
        like dies { my ($data, $err) = too_many_result() },    qr!Invalid result tuple \(T, E\) in `too_many_result`. Do you forget to call `Ok` or `Err` function\? Got: \[1,2,3\]!;
        like dies { my ($data, $err) = never_return_error() }, qr!Never return error in `never_return_error`: \[undef,'foo'\]!;
    };

    subtest 'Must handle error' => sub {
        like dies { my $result = valid() }, qr/Must handle error in `valid`/;
    };

    subtest 'Result(T, E) requires `check` method' => sub {
        eval "sub invalid_type_T :Result('HELLO', NonEmptyStr) { Ok('HELLO') }";
        like $@, qr/Result T requires `check` method/;

        eval "sub invalid_type_E :Result(Int, 'WORLD') { Err('WORLD') }";
        like $@, qr/Result E requires `check` method/;
    };

    subtest 'E should not allow falsy values' => sub {
        eval "sub should_not_allow_falsy :Result(Int, Int) { }";
        like $@, qr/Result E should not allow falsy values: \[0,'0'\]/;
    };
};

subtest 'Test the details of :Result attribute' => sub {
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
