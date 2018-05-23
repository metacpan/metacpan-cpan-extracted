
use Test::More;

use Sub::Replace;

{
    sub one {'One'}

    is( one(), 'One', 'one() - original' );

    BEGIN {
        Sub::Replace::sub_replace( 'one', sub {'Uno'} );
    }

    is( one(), 'Uno', 'one() - replace once' );

    BEGIN {
        Sub::Replace::sub_replace( 'one', sub {'Eins'} );
    }

    is( one(), 'Eins', 'one() - replace twice' );

    BEGIN {
        Sub::Replace::sub_replace( 'one', undef );
    }

    ok( !exists &one, 'one() - undefined' );
}

{
    sub foo {42}

    is( foo(), 42, 'foo() - original' );

    my $old;

    BEGIN {
        $old = Sub::Replace::sub_replace( 'foo', sub {43} );
    }

    is( foo(), 43, 'foo() - replaced' );

    BEGIN {
        Sub::Replace::sub_replace($old);
    }

    is( foo(), 42, 'foo() - restored' );
}

{
    my $old;

    BEGIN {
        $old = Sub::Replace::sub_replace( bar => sub {'xyz'} );
    }

    is( bar(), 'xyz', 'bar() - defined by replacement' );

    BEGIN {
        Sub::Replace::sub_replace($old);
    }

    ok( !exists &bar, 'bar() - back to undefined' );
}

done_testing;
