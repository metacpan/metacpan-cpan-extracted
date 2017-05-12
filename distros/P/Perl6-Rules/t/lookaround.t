use Perl6::Rules;
use Test::Simple 'no_plan';

rule bc { b?c }

ok( "a cdef" =~ m/<after a <sp> c> def/, "Lookbehind" );
ok( "acdef" !~ m/<after a <sp> c> def/, "Lookbehind failure" );
ok( "a cdef" !~ m/<!after a <sp> c> def/, "Negative lookbehind failure" );
ok( "acdef" =~ m/<!after a <sp> c> def/, "Negative lookbehind" );

ok( "abcd f" =~ m/abc <before d <sp> f> (.)/, "Lookahead" );
ok( $1 eq 'd', "Verify lookahead" );
ok( "abcdef" !~ m/abc <before d <sp> f>/, "Lookahead failure" );
ok( "abcd f" !~ m/abc <!before d <sp> f>/, "Negative lookahead failure" );
ok( "abcdef" =~ m/abc <!before d <sp> f> (.)/, "Negative lookahead" );
ok( $1 eq 'd', "Verify negative lookahead" );
