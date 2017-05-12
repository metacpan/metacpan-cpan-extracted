use Perl6::Rules;
use Test::Simple 'no_plan';

ok( "abcabcabcabcd" =~ m/[abc]<4>/, "Fixed exact repetition" );
ok( "abcabcabcabcd" !~ m/[abc]<5>/, "Fail fixed exact repetition" );
ok( "abcabcabcabcd" =~ m/[abc]<2,4>/, "Fixed range repetition" );
ok( "abcabcabcabcd" =~ m/[abc]<2,4>/, "Fixed range repetition" );
ok( "abc"           !~ m/[abc]<2,4>/, "Fail fixed range repetition" );
ok( "abcabcabcabcd" =~ m/[abc]<2,>/, "Open range repetition" );
ok( "abcd"          !~ m/[abc]<2,>/, "Fail open range repetition" );
