use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;
use Test2::Require::Module 'Type::Tiny' => '0.024';

use Params::ValidationCompiler qw( validation_for );
use Types::Standard qw( ArrayRef Int );

subtest(
    'type can be inlined',
    sub {
        _test_int_type(Int);
    }
);

my $myint = Type::Tiny->new(
    name       => 'MyInt',
    constraint => sub {/\A-?[0-9]+\z/},
);

subtest(
    'type cannot be inlined',
    sub {
        _test_int_type($myint);
    }
);

subtest(
    'type and coercion can be inlined',
    sub {
        my $type = ( ArrayRef [Int] )->plus_coercions(
            Int, '[$_]',
        );

        _test_int_to_arrayref_coercion($type);
    }
);

subtest(
    'type can be inlined but coercion cannot',
    sub {
        my $type = ( ArrayRef [Int] )->plus_coercions(
            Int, sub { [$_] },
        );

        _test_int_to_arrayref_coercion($type);
    }
);

# XXX - if the type cannot be inlined then the coercion reports itself as
# uninlinable as well, but that could change in the future.
subtest(
    'type cannot be inlined but coercion can',
    sub {
        my $type = ( ArrayRef [$myint] )->plus_coercions(
            $myint, '[$_]',
        );

        _test_int_to_arrayref_coercion($type);
    }
);

subtest(
    'neither type not coercion can be inlined',
    sub {
        my $type = ( ArrayRef [$myint] )->plus_coercions(
            $myint, sub { [$_] },
        );

        _test_int_to_arrayref_coercion($type);
    }
);

done_testing();

sub _test_int_type {
    my $type = shift;

    my $sub = validation_for(
        params => {
            foo => { type => $type },
        },
    );

    is(
        dies { $sub->( foo => 42 ) },
        undef,
        'lives when foo is an integer'
    );

    my $name = $type->display_name;
    like(
        dies { $sub->( foo => [] ) },
        qr/\QReference [] did not pass type constraint "$name"/,
        'dies when foo is an arrayref'
    );
}

sub _test_int_to_arrayref_coercion {
    my $type = shift;

    my $sub = validation_for(
        params => {
            foo => { type => $type },
        },
    );

    is(
        dies { $sub->( foo => 42 ) },
        undef,
        'lives when foo is an integer'
    );

    is(
        dies { $sub->( foo => [ 42, 1 ] ) },
        undef,
        'lives when foo is an arrayref of integers'
    );

    my $name = $type->display_name;
    like(
        dies { $sub->( foo => {} ) },
        qr/\QReference {} did not pass type constraint "$name"/,
        'dies when foo is a hashref'
    );
}
