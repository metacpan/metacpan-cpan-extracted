package t::Net::ACME2::PromiseUtil;

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Net::ACME2::PromiseUtil;

{
    my @passed;

    my $got = Net::ACME2::PromiseUtil::then( 55, sub { @passed = @_; 42 } );

    is( "@passed", 55, 'value passed to callback' );
    is( $got, 42, 'value returned from callback' );
}

{
    my $ran;
    my $todo_cr = sub { $ran = 1; 32 };

    my $mock_promise = bless {}, 't::FakePromise';

    my $got = Net::ACME2::PromiseUtil::then( $mock_promise, $todo_cr );

    is_deeply(
        \@t::FakePromise::TO_THEN,
        [ $todo_cr ],
        'callback given to then()',
    );

    is( $got, 42, 'then() return is returned' );
}

{
    my (@to_try, @to_catch);

    my $try_cr = sub { @to_try = @_; 32 };
    my $catch_cr = sub { @to_catch = @_; 42 };

    my $got = Net::ACME2::PromiseUtil::do_then_catch(
        sub { 123 },
        $try_cr,
        $catch_cr,
    );

    is_deeply( \@to_try, [ 123 ], 'value given to try cb' );
    is( $got, 32, 'try cb’s return given back' );
}

{
    my (@to_try, @to_catch);

    my $try_cr = sub { @to_try = @_; 32 };
    my $catch_cr = sub { @to_catch = @_; 42 };

    my $got = Net::ACME2::PromiseUtil::do_then_catch(
        sub { die "123\n" },
        $try_cr,
        $catch_cr,
    );

    is_deeply( \@to_catch, [ "123\n" ], 'value given to catch cb' );
    is( $got, 42, 'catch cb’s return given back' );
}

{
    @t::FakePromise::TO_THEN = ();

    my $try_cr = sub {};
    my $catch_cr = sub {};

    my $got = Net::ACME2::PromiseUtil::do_then_catch(
        sub { return bless {}, 't::FakePromise' },
        $try_cr,
        $catch_cr,
    );

    is_deeply(
        \@t::FakePromise::TO_THEN,
        [ $try_cr, $catch_cr ],
        'callbacks given to then()',
    );

    is( $got, 42, 'then()’s return given back' );
}

#----------------------------------------------------------------------

done_testing;

#----------------------------------------------------------------------

package t::FakePromise;

our (@TO_THEN);

sub then {
    shift;
    @TO_THEN = @_;
    return 42;
}
