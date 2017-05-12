use strict;
use warnings;

use Test::Needs 'Moo';

use Test::Fatal;
use Test::More 0.96;

{
    package Foo;

    use Specio::Declare;
    use Specio::Library::Builtins;

    use Moo;

    ::is(
        ::exception { has size => (
                is  => 'ro',
                isa => t('Int'),
            );
        },
        undef,
        'no exception passing a Specio object as the isa parameter for a Moo attr'
    );

    has numbers => (
        is  => 'ro',
        isa => t( 'ArrayRef', of => t('Int') ),
    );

    my $ucstr = declare(
        'UCStr',
        parent => t('Str'),
        where  => sub { $_[0] =~ /^[A-Z]+$/ },
    );

    coerce(
        $ucstr,
        from  => t('Str'),
        using => sub { return uc $_[0] },
    );

    has ucstr => (
        is     => 'ro',
        isa    => $ucstr,
        coerce => $ucstr->coercion_sub,
    );

    my $ucstr2 = declare(
        'Ucstr2',
        parent    => t('Str'),
        inline_as => sub {
            my $type      = shift;
            my $value_var = shift;

            return $value_var . ' =~ /^[A-Z]+$/';
        },
    );

    coerce(
        $ucstr2,
        from  => t('Str'),
        using => sub { return uc $_[0] },
    );

    has ucstr2 => (
        is     => 'ro',
        isa    => $ucstr2,
        coerce => $ucstr2->coercion_sub,
    );

    my $ucstr3 = declare(
        'Ucstr3',
        parent => t('Str'),
        where  => sub { $_[0] =~ /^[A-Z]+$/ },
    );

    coerce(
        $ucstr3,
        from             => t('Str'),
        inline_generator => sub {
            my $coercion  = shift;
            my $value_var = shift;

            return 'uc ' . $value_var;
        },
    );

    has ucstr3 => (
        is     => 'ro',
        isa    => $ucstr3,
        coerce => $ucstr3->coercion_sub,
    );

    my $ucstr4 = declare(
        'Ucstr4',
        parent    => t('Str'),
        inline_as => sub {
            my $type      = shift;
            my $value_var = shift;

            return $value_var . ' =~ /^[A-Z]+$/';
        },
    );

    coerce(
        $ucstr4,
        from             => t('Str'),
        inline_generator => sub {
            my $coercion  = shift;
            my $value_var = shift;

            return 'uc ' . $value_var;
        },
    );

    has ucstr4 => (
        is     => 'ro',
        isa    => $ucstr4,
        coerce => $ucstr4->coercion_sub,
    );
}

is(
    exception { Foo->new( size => 42 ) },
    undef,
    'no exception with new( size => $int )'
);

like(
    exception { Foo->new( size => 'foo' ) },
    qr/\QValidation failed for type named Int\E.+\Qwith value "foo"/,
    'got exception with new( size => $str )'
);

is(
    exception { Foo->new( numbers => [ 1, 2, 3 ] ) },
    undef,
    'no exception with new( numbers => [$int, $int, $int] )'
);

is(
    exception { Foo->new( ucstr => 'ABC' ) },
    undef,
    'no exception with new( ucstr => $ucstr )'
);

{
    my $foo;
    is(
        exception { $foo = Foo->new( ucstr => 'abc' ) },
        undef,
        'no exception with new( ucstr => $lcstr )'
    );

    is(
        $foo->ucstr,
        'ABC',
        'ucstr attribute was coerced to upper case'
    );
}

{
    my $foo;
    is(
        exception { $foo = Foo->new( ucstr2 => 'abc' ) },
        undef,
        'no exception with new( ucstr2 => $lcstr )'
    );

    is(
        $foo->ucstr2,
        'ABC',
        'ucstr2 attribute was coerced to upper case'
    );
}

{
    my $foo;
    is(
        exception { $foo = Foo->new( ucstr3 => 'abc' ) },
        undef,
        'no exception with new( ucstr3 => $lcstr )'
    );

    is(
        $foo->ucstr3,
        'ABC',
        'ucstr3 attribute was coerced to upper case'
    );
}

{
    my $foo;
    is(
        exception { $foo = Foo->new( ucstr4 => 'abc' ) },
        undef,
        'no exception with new( ucstr4 => $lcstr )'
    );

    is(
        $foo->ucstr4,
        'ABC',
        'ucstr4 attribute was coerced to upper case'
    );
}

# There was a bug in Specio for any attribute with a type with more than one
# coercion. In order to guarantee that it occurs, you need a a class with just
# one attribute.
{
    ## no critic (Modules::ProhibitMultiplePackages)
    package Bar;

    use Specio::Declare;
    use Specio::Library::Builtins;

    use Moo;

    coerce(
        t('Str'),
        from             => t('ArrayRef'),
        inline_generator => sub {
            my $coercion  = shift;
            my $value_var = shift;

            return "join q{}, \@{$value_var}";
        },
    );

    coerce(
        t('Str'),
        from             => t('HashRef'),
        inline_generator => sub {
            my $coercion  = shift;
            my $value_var = shift;

            return "join q{}, keys %{$value_var}";
        },
    );

    has bar => (
        is     => 'ro',
        isa    => t('Str'),
        coerce => t('Str')->coercion_sub,
    );
}

{
    is(
        exception { Bar->new( bar => ['a'], ) },
        undef,
        q{no exception with Bar->new( bar => ['a'] )}
    );

    is(
        exception { Bar->new( bar => { a => 1 } ) },
        undef,
        q{no exception with Bar->new( bar => { a => 1 } )}
    );
}

done_testing();
