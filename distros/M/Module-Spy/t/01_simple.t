use strict;
use warnings;
use utf8;
use Test::More;
use Module::Spy;
use Scalar::Util qw(refaddr);

use FindBin;
use lib "$FindBin::Bin/lib";
use X;

$|++;

subtest 'Spy class method (not required yet)' => sub {
    my $last_warning;
    local $SIG{__WARN__} = sub { $last_warning = $_[0] };

    ok ! exists $INC{'Truman.pm'};

    my $spy = spy_on('Truman', 'name');
    require Truman;

    is $last_warning, undef;
};

subtest 'Spy class method', sub {
    subtest 'Not called yet', sub {
        # Given set spy
        my $spy = spy_on('X', 'y');

        # Then, it's not called
        ok !$spy->called;
    };

    subtest 'Called', sub {
        # Given set spy
        my $spy = spy_on('X', 'y');

        # When call the method
        local $X::Y_CNT = 0;
        is +X->y, undef;

        # Then, it's called.
        ok $spy->called;
        # And, original method did not called.
        is $X::Y_CNT, 0;
    };

    subtest 'Call through', sub {
        # Given set spy
        my $spy = spy_on('X', 'y')->and_call_through;

        # Then, return value is original's
        local $X::Y_CNT = 0;
        is +X->y, 'yyy';

        # Then, it's called.
        ok $spy->called;
        # And, original method was called.
        is $X::Y_CNT, 1;
    };

    subtest 'Call fake', sub {
        my $called;

        # Given set spy
        my $spy = spy_on('X', 'y')->and_call_fake(sub { $called++; 5963 });

        # Then, return value is undef
        local $X::Y_CNT = 0;
        is +X->y(), 5963;

        # Then, it's called.
        ok $spy->called;

        # Then, the coderef was called.
        is $called, 1;

        # And, original method did not called.
        is $X::Y_CNT, 0;
    };

    subtest 'Restored', sub {
        {
            # Given set spy
            my $spy = spy_on('X', 'y');
        }

        # When it's out-scoped

        # Then, it's restored
        is ref(X->can('y')), 'CODE';
    };

    subtest 'Stub-out by value', sub {
        # Given set spy
        my $spy = spy_on('X', 'y');

        # When set return value as 3
        is refaddr($spy->and_returns(3)), refaddr($spy);

        # Then return value is 3
        is(X->y, 3);
    };

    subtest 'Stub-out by array value', sub {
        # Given set spy
        my $spy = spy_on('X', 'y');

        # When set return value as (3, 5)
        is refaddr($spy->and_returns(3, 5)), refaddr($spy);

        # Then return value is (3, 5)
        my @ret = X->y;
        is($ret[0], 3);
        is($ret[1], 5);
    };
};

subtest 'Spy instance method', sub {
    subtest 'Not called yet', sub {
        # Given object
        my $obj = X->new;

        # Given set spy
        my $spy = spy_on($obj, 'y');

        # Then, it's not called
        ok !$spy->called;
    };

    subtest 'Called', sub {
        # Given object
        my $obj = X->new;

        # Given set spy
        my $spy = spy_on($obj, 'y');

        # When call the method
        local $X::Y_CNT = 0;
        is $obj->y, undef;

        # Then, it's called.
        ok $spy->called;

        # And, original method did not called.
        is $X::Y_CNT, 0;
    };

    subtest 'Call through', sub {
        # Given object
        my $obj = X->new;

        # Given set spy
        my $spy = spy_on($obj, 'y')->and_call_through;

        # Then, return value is 'yyy'
        local $X::Y_CNT = 0;
        is $obj->y, 'yyy';

        # Then, it's called.
        ok $spy->called;

        # And, original method was called.
        is $X::Y_CNT, 1;
    };

    subtest 'Call fake', sub {
        # Given object
        my $obj = X->new;

        # Given set spy
        my $called = 0;
        my $spy = spy_on($obj, 'y')->and_call_fake(sub {
            $called++; 4649;
        });

        # Then, return value is 'yyy'
        local $X::Y_CNT = 0;
        is $obj->y, 4649;

        # Then, it's called.
        ok $spy->called;
        is $called, 1;

        # And, original method was not called.
        is $X::Y_CNT, 0;
    };

    subtest "It's restore methods after out scoped", sub {
        # Given object
        my $obj = X->new();

        {
            # When, set spy
            my $spy = spy_on($obj, 'y');

            # Then, it's spy-ed.
            is $obj->y, undef;
            # And, spy was called
            ok $spy->called;
        }

        # When scoped out,
        # Then, it's restored.
        is +X->y, 'yyy';
    };

    subtest "It's not affected for another object", sub {
        # Given object
        my $obj = X->new;

        # Given another object
        my $another_obj = X->new;

        # Given set spy
        my $spy = spy_on($obj, 'y');

        # Then, $obj was spyed
        is ref($obj->can('y')), 'Module::Spy::Sub';

        # Then, but $another_obj was *not* spyed
        is ref($another_obj->can('y')), 'CODE';
    };
};

done_testing;

