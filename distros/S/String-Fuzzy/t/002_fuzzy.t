#!perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib './lib';
our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;

use String::Fuzzy qw(
    ratio
    partial_ratio
    token_sort_ratio
    token_set_ratio
    fuzzy_substring_ratio
    extract_best
    extract_all
);

# Basic ratio
is( ratio( 'hello', 'hello' ), 100, 'Exact match ratio is 100 (normalized)' );
ok( ratio( 'hello', 'helo' ) > 70, 'hello vs helo has good ratio (normalized)' );
is( ratio( 'Hello', 'hello', normalize => 0 ), 80, 'Case-sensitive ratio without normalization' );

# Input string for matching
my $filename = "SpakPost Invoice No INV00123456_67890_11223344.pdf";
my $query    = "SparkPost";
my @vendors  = qw( SendGrid Mailgun SparkPost Postmark );

my $score = partial_ratio( "SparkPost", "SpakPost Invoice" );
ok( $score >= 85, "Partial ratio handles typo substring (got $score)" );
diag( "Debug: sparkpost vs spakpost = ", ratio( "sparkpost", "spakpost" ) ) if( $DEBUG );
diag( "Debug: s1_len = ", length("sparkpost"), ", s2_len = ", length("spakpost invoice") ) if( $DEBUG );

is( ratio( "SparkPost", "SparkPost" ), 100, 'Exact match ratio' );
ok( partial_ratio( "SparkPost", "SpakPost Invoice" ) >= 85, 'Partial ratio handles typo substring' );
is( partial_ratio( "cat", "category" ), 100, 'Partial ratio detects full containment' );
ok( fuzzy_substring_ratio( "SparkPost", $filename ) >= 88, 'fuzzy_substring_ratio matches inside noisy string' );
is( token_sort_ratio( "post spark", "Spark Post" ), 100, 'token_sort_ratio normalizes word order' );
ok( token_set_ratio( "Invoice SparkPost", "SparkPost Invoice" ) >= 95, 'token_set_ratio handles token intersection' );

# extract_best with typo
my $best = extract_best( "SpakPost", \@vendors, scorer => \&ratio );
if( !defined( $best ) )
{
    fail( 'extract_best returned undef for SpakPost' );
}
elsif ( ref( $best ) ne 'ARRAY' )
{
    fail( 'extract_best did not return an arrayref' );
}
else
{
    is( $best->[0], 'SparkPost', 'extract_best finds correct vendor' );
    ok( $best->[1] >= 80, 'extract_best score is reasonable' );
    is( $best->[2], 2, 'extract_best returns correct index (SparkPost is at index 2)' );
}

# extract_all returns sorted list by score
my $results = extract_all( "SpakPost", \@vendors, scorer => \&ratio );
if( !defined( $results ) )
{
    fail( 'extract_all returned undef' );
}
elsif( ref( $results ) ne 'ARRAY' )
{
    fail( 'extract_all did not return an arrayref' );
}
elsif( scalar( @$results ) != scalar( @vendors ) )
{
    fail( 'extract_all returned wrong number of results' );
}
else
{
    is( $results->[0]->[0], 'SparkPost', 'extract_all ranks SparkPost highest' );
    ok( $results->[0]->[1] >= 80, 'Top match has high score' );
    ok( $results->[1]->[1] <= $results->[0]->[1], 'Results are sorted by score descending' );
}

# Normalization toggle
is( ratio( "café", "cafe" ), 100, 'Diacritics are normalized by default' );
$score = ratio( "café", "cafe", normalize => 0 );
is( $score, 80, "Diacritics matter without normalization (got $score)" );
diag( "Debug: distance = ", String::Fuzzy::distance("café", "cafe"), ", len1 = ", length("café"), ", len2 = ", length("cafe") ) if( $DEBUG );

# Edge cases
is( ratio( "", "SparkPost" ), 0, 'Empty string against text gives 0' );
is( ratio( "", "" ), 100, 'Two empty strings are equal, score is 100' );
is( ratio( "a", "b" ), 0, 'Single-char mismatch gives 0' );

# Fuzzy substring matching
ok( fuzzy_substring_ratio( "SparkPost", "Monthly email from SpakPost Services" ) >= 85, 'Match found in middle of string' );
ok( ratio( "cat", "cut" ) >= 66, 'Small strings with 1 char diff (float precision)' );

# Additional tests for float precision
my $float_score = ratio( "hello", "helo" );
if ( !defined( $float_score ) )
{
    fail( 'ratio returned undef for hello vs helo' );
}
else
{
    ok( $float_score > 79 && $float_score < 81, 'Ratio returns float (hello vs helo ~80)' );
}

# Test partial_ratio with normalization disabled
is( partial_ratio( "Cat", "category", normalize => 0 ), 66.66666666666666, 'Case-sensitive partial match' );

# Test undef handling
is( ratio( undef, "cafe" ), 0, "Undef s1 returns 0" );
is( ratio( "cafe", undef ), 0, "Undef s2 returns 0" );

is_deeply( extract_all( undef, ["a", "b"] ), [], "extract_all with undef query returns empty" );
is( extract_best( undef, ["a", "b"] ), undef, "extract_best with undef query returns undef" );

# NOTE: Test stringifiable object
# Hide it from MetaCPAN
package
    Stringy;
use overload '""' => sub { "hello" };
sub new { bless {}, shift; }
package main;
my $obj = Stringy->new;
is( ratio( $obj, "hello" ), 100, "Stringifiable object works" );

# Test unstringifiable reference
eval { ratio( [], "cafe" ); fail( "Should die on unstringifiable ref" ); };
ok( $@ =~ /not references/, "Dies on unstringifiable ref" );

done_testing();

__END__