use strict;
use warnings;

use Test::More 0.96;

use Specio::Declare;
use Specio::Library::Builtins;

{
    my $anon = anon(
        parent => t('Str'),
        where  => sub { length $_[0] },
    );

    isa_ok( $anon, 'Specio::Constraint::Simple', 'return value from anon' );

    ok( $anon->value_is_valid('x'),  q{anon type allows "x"} );
    ok( !$anon->value_is_valid(q{}), 'anon type reject empty string' );
}

{
    my $anon = anon(
        parent => t('Str'),
        inline => sub {
            $_[0]->parent->inline_check( $_[1] ) . " && length $_[1]";
        },
    );

    isa_ok( $anon, 'Specio::Constraint::Simple', 'return value from anon' );

    ok( $anon->value_is_valid('x'), q{inlinable anon type allows "x"} );
    ok(
        !$anon->value_is_valid(q{}),
        'inlinable anon type reject empty string'
    );
}

done_testing();
