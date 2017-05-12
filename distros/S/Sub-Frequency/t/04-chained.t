
use Test::More tests => 1;

use Sub::Frequency;

{
    my $foo = 0;
    never { $foo++ } always { $foo-- } for 1 .. 100;
    is( $foo, -100, 'if never else always' );
}

