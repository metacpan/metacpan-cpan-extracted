use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

use Params::ValidationCompiler qw( validation_for );
use Specio::Declare;
use Specio::Library::Builtins;

subtest(
    'type can be inlined',
    sub {
        _test_int_type( t('Int') );
    }
);

declare(
    'MyInt',
    where => sub { $_[0] =~ /\A-?[0-9]+\z/ },
);

declare(
    'MyInt2',
    where => sub { $_[0] =~ /\A-?[0-9]+\z/ },
);

declare(
    'ArrayRefOfInt',
    parent => t( 'ArrayRef', of => t('Int') ),
);

declare(
    'ArrayRefOfInt2',
    parent => t( 'ArrayRef', of => t('Int') ),
);

subtest(
    'type cannot be inlined',
    sub {
        _test_int_type( t('MyInt') );
    }
);

subtest(
    'type and coercion can be inlined',
    sub {
        coerce(
            t('ArrayRefOfInt'),
            from   => t('Int'),
            inline => sub { return "[ $_[1] ]" },
        );

        _test_arrayref_to_int_coercion( t('ArrayRefOfInt') );
    }
);

subtest(
    'type can be inlined but coercion cannot',
    sub {
        coerce(
            t('ArrayRefOfInt2'),
            from  => t('Int'),
            using => sub { return [ $_[0] ] },
        );

        _test_arrayref_to_int_coercion( t('ArrayRefOfInt2') );
    }
);

subtest(
    'type cannot be inlined but coercion can',
    sub {
        coerce(
            t('MyInt'),
            from   => t('ArrayRef'),
            inline => sub { return "scalar \@{ $_[1] }" },
        );

        _test_arrayref_to_int_coercion( t('MyInt') );
    }
);

subtest(
    'neither type not coercion can be inlined',
    sub {
        coerce(
            t('MyInt2'),
            from  => t('ArrayRef'),
            using => sub { return scalar @{ $_[0] } },
        );

        _test_arrayref_to_int_coercion( t('MyInt2') );
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

    my $name = $type->name;
    like(
        dies { $sub->( foo => [] ) },
        qr/Validation failed for type named $name declared in .+ with value \Q[  ]/,
        'dies when foo is an arrayref'
    );
}

sub _test_arrayref_to_int_coercion {
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

    my $name = $type->name;
    like(
        dies { $sub->( foo => {} ) },
        qr/Validation failed for type named $name declared in .+ with value \Q{  }/,
        'dies when foo is a hashref'
    );
}
