#!perl -w
use Test::More tests => 4;
use lib 't/lib';
use Test::IsEscapes qw( isq );
use Term::HiliteDiff;

my $d = Term::HiliteDiff->new;
isq( $d->hilite_diff( 'xxx xxx xxx' ), 'xxx xxx xxx','xxx xxx xxx' );
isq( $d->hilite_diff( 'xxx xxx AAA' ), "xxx xxx \e[7mAAA\e[0m",'xxx xxx AAA' );
isq( $d->hilite_diff( 'xxx BBB xxx' ), "xxx \e[7mBBB\e[0m \e[7mxxx\e[0m",'xxx BBB xxx' );
isq( $d->hilite_diff( 'CCC xxx xxx' ), "\e[7mCCC\e[0m \e[7mxxx\e[0m xxx", 'CCC xxx xxx' );
