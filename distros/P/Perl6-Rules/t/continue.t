use Perl6::Rules; 
use Test::Simple 'no_plan';

for ("abcdef") {
	ok( m:cont/abc/, "Matched 1: '$0'" );
	ok( pos == 3, "Interim position correct" );
	ok( m:cont/ghi|def/, "Matched 2: '$0'" );
	ok( pos == 6, "Final position correct" );
}

$_ = "foofoofoo foofoofoo";
ok( s:globally:cont/foo/FOO/, "Globally contiguous substitution" );
ok( $_ eq "FOOFOOFOO foofoofoo", "Correctly substituted contiguously" );
