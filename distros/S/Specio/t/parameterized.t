use strict;
use warnings;

use Test::Fatal;
use Test::More 0.96;

use Specio::Declare;
use Specio::Library::Builtins;

{
    my $arrayref = t('ArrayRef');

    ok(
        $arrayref->value_is_valid( [ {}, 42, 'foo' ] ),
        'ArrayRef does not care about member types'
    );

    my $from_method = t1($arrayref);

    for my $pair (
        [ filename   => __FILE__ ],
        [ line       => 42 ],
        [ package    => 'main' ],
        [ subroutine => 'main::t1' ],
        ) {

        my ( $key, $expect ) = @{$pair};
        is(
            $from_method->declared_at->$key,
            $expect,
            "declared_at $key is the expected value for parameterized type made from ->parameterize"
        );
    }

    my $from_t = t2();

    for my $pair (
        [ filename   => __FILE__ ],
        [ line       => 84 ],
        [ package    => 'main' ],
        [ subroutine => 'main::t2' ],
        ) {

        my ( $key, $expect ) = @{$pair};
        is(
            $from_t->declared_at->$key,
            $expect,
            "declared_at $key is the expected value for parameterized type made from calling t"
        );
    }

    declare(
        'ArrayRefOfInt',
        parent => t( 'ArrayRef', of => t('Int') ),
    );

    ok(
        t('ArrayRefOfInt'),
        'there is an ArrayRefOfInt type declared'
    );

    my $anon = anon(
        parent => t( 'ArrayRef', of => t('Int') ),
    );

    for my $pair (
        [ $from_method,       '->parameterize' ],
        [ $from_t,            't(...)' ],
        [ t('ArrayRefOfInt'), 'named type' ],
        [ $anon,              'anon type' ],
        ) {

        my ( $arrayref_of_int, $desc ) = @{$pair};

        ok(
            !$arrayref_of_int->value_is_valid( [ {}, 42, 'foo' ] ),
            "ArrayRef of Int [$desc] does care about member types"
        );

        ok(
            $arrayref_of_int->value_is_valid( [ -1, 42, 1_000_000 ] ),
            "ArrayRef of Int [$desc] accepts array ref of all integers"
        );

        ok(
            !$arrayref_of_int->value_is_valid(42),
            "ArrayRef of Int [$desc] rejects integer"
        );

        ok(
            !$arrayref_of_int->value_is_valid( {} ),
            "ArrayRef of Int [$desc] rejects hashref"
        );
    }
}

{
    like(
        exception {
            declare(
                'MyInt',
                where => sub { $_[0] =~ /\A-?[0-9]+\z/ },
            );
            declare(
                'ArrayRefOfMyInt',
                parent => t( 'ArrayRef', of => t('MyInt') ),
            );
        },
        qr/\QThe "of" parameter passed to ->parameterize must be an inlinable constraint if the parameterizable type has an inline_generator/,
        'A parameterizable type with an inline generator cannot be parameterized with a type that cannot be inlined',
    );
}

done_testing();

sub t1 {
    my $arrayref = shift;
# line 42
    return $arrayref->parameterize( of => t('Int') );
}

sub t2 {
# line 84
    return t( 'ArrayRef', of => t('Int') ),;
}
