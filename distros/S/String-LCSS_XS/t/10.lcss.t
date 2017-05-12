use Test::More tests => 15;
use strict;

use String::LCSS_XS qw(lcss);


my $longest = lcss ( "xyzzx", "abcxyzefg" );
is ( $longest, "xyz", "xyzzx vs abcxyzefg" );

$longest = lcss ( "abcxyzzx", "abcxyzefg" );
is ( $longest, "abcxyz", "abcxyzzx vs abcxyzefg" );

$longest = lcss ( "foobar", "abcxyzefg" );
is ( $longest, 'a', "foobar vs abcxyzefg" );

$longest = lcss ( "foobar", "abcxyzefg", 1 );
is ( $longest, 'a', "foobar vs abcxyzefg" );

$longest = lcss ( "foobar", "abcxyzefg", 2 );
is ( $longest, undef, "foobar vs abcxyzefg with min=2" );

my $needle = "i pushed the lazy dog into a creek, the quick brown fox told me to";
my $haystack = "the quick brown fox jumps over the lazy dog";

$longest = lcss ( $needle, $haystack );
is ( $longest, "the quick brown fox ", "the quick brown fox" );

$longest = lcss ( $haystack, $needle );
is ( $longest, "the quick brown fox ", "the quick brown fox (reverse args)" );

$haystack = "why did the quick brown fox jumps over the lazy dog";
$longest = lcss ( $needle, $haystack );
is ( $longest, " the quick brown fox ", "why did the quick brown fox" );

$longest = lcss ( 'ABBAGGG', 'HHHHZZAB');
is ($longest, 'AB', 'ABBA at the beginning and end');

$longest = lcss ( 'HHHHZZAB', 'ABBAGGG');
is ($longest, 'AB', 'ABBA at the beginning and end (reverse args)');

my @result = lcss ( "zyzxx", "abczyzefg" );
is_deeply(\@result, [ 'zyz',0,3], 'wantarray returns positions');

$longest = lcss ( 'b', 'ab' );
is($longest, 'b', 'bug in LCSS');

$longest = lcss ( "123", "ABCD" );
is($longest, undef, 'undef when there is no cs');

$longest = lcss ( undef, "ABCD" );
is($longest, undef, 'undef when one string is undef');

$longest = lcss ( "ABCD", undef );
is($longest, undef, 'undef when one string is undef');
