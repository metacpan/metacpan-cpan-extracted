#!perl -w
use Test::More tests => 32;
use lib 't/lib';
use Test::IsEscapes qw( isq isaq );
use Term::HiliteDiff ();

my $d;

# hilite_diff with array input
$d = Term::HiliteDiff->new;
isaq( $d->hilite_diff( [qw[ xxx xxx xxx ]] ), ['xxx','xxx','xxx'],                     'hilite_diff array' );
isaq( $d->hilite_diff( [qw[ xxx xxx AAA ]] ), ['xxx','xxx',"\e[7mAAA\e[0m"],           'hilite_diff array' );
isaq( $d->hilite_diff( [qw[ xxx BBB xxx ]] ), ['xxx',"\e[7mBBB\e[0m","\e[7mxxx\e[0m"], 'hilite_diff array' );
isaq( $d->hilite_diff( [qw[ CCC xxx xxx ]] ), ["\e[7mCCC\e[0m","\e[7mxxx\e[0m",'xxx'], 'hilite_diff array' );

$d = Term::HiliteDiff->new;
isq( $d->hilite_diff( "xxx\txxx\txxx" ), "xxx\txxx\txxx",                     "xxx\\txxx\\txxx" );
isq( $d->hilite_diff( "xxx\txxx\tAAA" ), "xxx\txxx\t\e[7mAAA\e[0m",           "xxx\\txxx\\tAAA" );
isq( $d->hilite_diff( "xxx\tBBB\txxx" ), "xxx\t\e[7mBBB\e[0m\t\e[7mxxx\e[0m", "xxx\\tBBB\\txxx" );
isq( $d->hilite_diff( "CCC\txxx\txxx" ), "\e[7mCCC\e[0m\t\e[7mxxx\e[0m\txxx", "CCC\\txxx\\txxx" );

$d = Term::HiliteDiff->new;
isq( $d->hilite_diff( "xxx|xxx|xxx" ), "xxx|xxx|xxx",                     "xxx|xxx|xxx" );
isq( $d->hilite_diff( "xxx|xxx|AAA" ), "xxx|xxx|\e[7mAAA\e[0m",           "xxx|xxx|AAA" );
isq( $d->hilite_diff( "xxx|BBB|xxx" ), "xxx|\e[7mBBB\e[0m|\e[7mxxx\e[0m", "xxx|BBB|xxx" );
isq( $d->hilite_diff( "CCC|xxx|xxx" ), "\e[7mCCC\e[0m|\e[7mxxx\e[0m|xxx", "CCC|xxx|xxx" );

$d = Term::HiliteDiff->new;
isq( $d->hilite_diff( "xxx\nxxx\nxxx" ), "xxx\nxxx\nxxx",                     "xxx\\nxxx\\nxxx" );
isq( $d->hilite_diff( "xxx\nxxx\nAAA" ), "xxx\nxxx\n\e[7mAAA\e[0m",           "xxx\\nxxx\\nAAA" );
isq( $d->hilite_diff( "xxx\nBBB\nxxx" ), "xxx\n\e[7mBBB\e[0m\n\e[7mxxx\e[0m", "xxx\\nBBB\\nxxx" );
isq( $d->hilite_diff( "CCC\nxxx\nxxx" ), "\e[7mCCC\e[0m\n\e[7mxxx\e[0m\nxxx", "CCC\\nxxx\\nxxx" );

# watch with array input
$d = Term::HiliteDiff->new;
isaq( $d->watch( [qw[ xxx xxx xxx ]] ), ["\e[sxxx\e[K","xxx\e[K","xxx\e[K"],                     'watch array' );
isaq( $d->watch( [qw[ xxx xxx AAA ]] ), ["\e[uxxx\e[K","xxx\e[K","\e[7mAAA\e[0m\e[K"],           'watch array' );
isaq( $d->watch( [qw[ xxx BBB xxx ]] ), ["\e[uxxx\e[K","\e[7mBBB\e[0m\e[K","\e[7mxxx\e[0m\e[K"], 'watch array' );
isaq( $d->watch( [qw[ CCC xxx xxx ]] ), ["\e[u\e[7mCCC\e[0m\e[K","\e[7mxxx\e[0m\e[K","xxx\e[K"], 'watch array' );

# 
$d = Term::HiliteDiff->new;
isq( $d->watch( "xxx\txxx\txxx" ), "\e[sxxx\txxx\txxx\e[K",                 "xxx\\txxx\\txxx" );
isq( $d->watch( "xxx\txxx\tAAA" ), "\e[uxxx\txxx\t\e[7mAAA\e[0m\e[K",           "xxx\\txxx\\tAAA" );
isq( $d->watch( "xxx\tBBB\txxx" ), "\e[uxxx\t\e[7mBBB\e[0m\t\e[7mxxx\e[0m\e[K", "xxx\\tBBB\\txxx" );
isq( $d->watch( "CCC\txxx\txxx" ), "\e[u\e[7mCCC\e[0m\t\e[7mxxx\e[0m\txxx\e[K", "CCC\\txxx\\txxx" );

$d = Term::HiliteDiff->new;
isq( $d->watch( "xxx|xxx|xxx" ), "\e[sxxx|xxx|xxx\e[K",                     "xxx|xxx|xxx" );
isq( $d->watch( "xxx|xxx|AAA" ), "\e[uxxx|xxx|\e[7mAAA\e[0m\e[K",           "xxx|xxx|AAA" );
isq( $d->watch( "xxx|BBB|xxx" ), "\e[uxxx|\e[7mBBB\e[0m|\e[7mxxx\e[0m\e[K", "xxx|BBB|xxx" );
isq( $d->watch( "CCC|xxx|xxx" ), "\e[u\e[7mCCC\e[0m|\e[7mxxx\e[0m|xxx\e[K", "CCC|xxx|xxx" );

$d = Term::HiliteDiff->new;
isq( $d->watch( "xxx\nxxx\nxxx" ), "\e[sxxx\e[K\nxxx\e[K\nxxx\e[K",                     "xxx\\nxxx\\nxxx" );
isq( $d->watch( "xxx\nxxx\nAAA" ), "\e[uxxx\e[K\nxxx\e[K\n\e[7mAAA\e[0m\e[K",           "xxx\\nxxx\\nAAA" );
isq( $d->watch( "xxx\nBBB\nxxx" ), "\e[uxxx\e[K\n\e[7mBBB\e[0m\e[K\n\e[7mxxx\e[0m\e[K", "xxx\\nBBB\\nxxx" );
isq( $d->watch( "CCC\nxxx\nxxx" ), "\e[u\e[7mCCC\e[0m\e[K\n\e[7mxxx\e[0m\e[K\nxxx\e[K", "CCC\\nxxx\\nxxx" );


# TODO: test that embedded \n are not colored over

# TODO: handle \n at the end of the last entry
