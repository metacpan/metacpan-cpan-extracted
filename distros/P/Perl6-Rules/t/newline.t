use Perl6::Rules;
use Test::Simple qw(no_plan) ;

# Some tests commented out due to Unicode problems
# See comment in module itself

ok( "\n" =~ m/\n/, "\\n" );

# ok( "\015\012" =~ m/\n/, "CR/LF" );
# ok( "\012" =~ m/\n/, "LF" );
# ok( "a\012" =~ m/\n/, "aLF" );
# ok( "\015" =~ m/\n/, "CR" );
# ok( "\x85" =~ m/\n/, "NEL");
# ok( "\x2028" =~ m/\n/, "LINE SEP");

ok( "abc" !~ m/\n/, "not abc");

ok( "\n" !~ m/\N/, "not \\n" );

# ok( "\012" !~ m/\N/, "not LF" );
# ok( "\015\012" !~ m/\N/, "not CR/LF" );
# ok( "\015" !~ m/\N/, "not CR" );
# ok( "\x85" !~ m/\N/, "not NEL");
# ok( "\x2028" !~ m/\N/, "not LINE SEP");

ok( "abc" =~ m/\N/, "abc" );
