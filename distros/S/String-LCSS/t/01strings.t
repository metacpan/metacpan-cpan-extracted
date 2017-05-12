
use strict;
use warnings;
use Test::More tests => 12;
use String::LCSS qw();

my $longest = String::LCSS::lcss ( "xyzzx", "abcxyzefg" );
is ( $longest, "xyz", "xyzzx vs abcxyzefg" );

$longest = String::LCSS::lcss ( "abcxyzzx", "abcxyzefg" );
is ( $longest, "abcxyz", "abcxyzzx vs abcxyzefg" );

$longest = String::LCSS::lcss ( "foobar", "abcxyzefg" );
is ( $longest, undef, "foobar vs abcxyzefg" );

my $needle = "i pushed the lazy dog into a creek, the quick brown fox told me to";
my $haystack = "the quick brown fox jumps over the lazy dog";

$longest = String::LCSS::lcss ( $needle, $haystack );
is ( $longest, "the quick brown fox ", "the quick brown fox" );

$longest = String::LCSS::lcss ( $haystack, $needle );
is ( $longest, "the quick brown fox ", "the quick brown fox (reverse args)" );

$haystack = "why did the quick brown fox jumps over the lazy dog";
$longest = String::LCSS::lcss ( $needle, $haystack );
is ( $longest, " the quick brown fox ", "why did the quick brown fox" );

$needle   = '1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 2 18 19 20 21 22 23 7 24';
$haystack = '1 2 3 4 5 7 8 9 11 12 13 10 14 15 16 17 2 18 19 20 21 22 23 7 24';
$longest = String::LCSS::lcss ( $needle, $haystack );
is ( $longest, ' 14 15 16 17 2 18 19 20 21 22 23 7 24', 'rt32036 bug');

$needle   = 'the quick brown fox jumped over the lazy dog';
$haystack = 'I saw a quick brown fox and jumped over the lazy dog'; 
$longest = String::LCSS::lcss ( $needle, $haystack );
is ( $longest, ' jumped over the lazy dog', 'rt62175 bug');

$longest = String::LCSS::lcss ( "abcdefg", "abcdefga" );
is ( $longest, 'abcdefg', 'another bug' );

$longest = String::LCSS::lcss ( "foo", "bar" );
is ( $longest, undef, 'no match' );

my @results;

@results = String::LCSS::lcss(qw(xyzzx abcxyzefg));
is_deeply(\@results, [qw(xyz 0 3)], 'array');

@results = String::LCSS::lcss(qw(AbCdefg AbCDef));
is_deeply(\@results, [qw(AbC 0 0)], 'array2');

