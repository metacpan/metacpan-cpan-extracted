
use Test::More tests => 4;

use Sub::Frequency;

{
    my $foo = 0;
    always { $foo++ } for 1 .. 100;
    is( $foo, 100, 'always' );
}

{
    my $foo = 0;
    ( with_probability 1 => sub { $foo++ } ) for 1 .. 100;
    ok( $foo, 'with probability 100%' );
}

{
    my $foo = 0;
    never { $foo++ } for 1 .. 100;
    is( $foo, 0, 'never');
}

{
    my $foo = 0;
    ( with_probability 0.50 => sub { $foo++ } ) for 1 .. 100;
    ok( 1, 'with probablity 50%');
}

