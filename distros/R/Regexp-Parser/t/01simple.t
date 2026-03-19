# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Parser.t'

use strict;
use warnings;

use Test::More tests => 13;
use Regexp::Parser;

my $r = Regexp::Parser->new;
my $rx = '^a+b*?c{5,}$';

ok( $r->regex($rx), 'parse regex' );

# for this regex, it's ok
# it won't necessarily ALWAYS be
is( $r->visual, $rx, 'visual roundtrip' );

ok( "aaabbbcccccc" =~ $r->qr, 'match aaabbbcccccc' );
ok( "aaabbbccccc"  =~ $r->qr, 'match aaabbbccccc' );
ok( "aaabbbcccc"   !~ $r->qr, 'no match aaabbbcccc (too few c)' );

ok( "aaabbbccccc" =~ $r->qr, 'match with 3 a' );
ok( "aaabbccccc"  =~ $r->qr, 'match with 2 b' );
ok( "aaabccccc"   =~ $r->qr, 'match with 1 b' );
ok( "aaaccccc"    =~ $r->qr, 'match with 0 b' );

ok( "aaabbbccccc" =~ $r->qr, 'match with 3 a prefix' );
ok( "aabbbccccc"  =~ $r->qr, 'match with 2 a prefix' );
ok( "abbbccccc"   =~ $r->qr, 'match with 1 a prefix' );
ok( "bbbccccc"    !~ $r->qr, 'no match without a' );
