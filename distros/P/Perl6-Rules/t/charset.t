use Perl6::Rules;
use Test::Simple 'no_plan';

ok( "zyxaxyz" =~ m/(<[aeiou]>)/, "Simple set" );
ok( $1 eq 'a', "Simple set capture" );
ok( "a" !~ m/<-[aeiou]>/, "Simple neg set failure" );
ok( "f" =~ m/(<-[aeiou]>)/, "Simple neg set match" );
ok( $1 eq 'f', "Simple neg set capture" );

ok( "a" !~ m/(<[a-z]-[aeiou]>)/, "Difference set failure" );
ok( "y" =~ m/(<[a-z]-[aeiou]>)/, "Difference set match" );
ok( $1 eq 'y', "Difference set capture" );
ok( "a" !~ m/(<<alpha>-[aeiou]>)/, "Named difference set failure" );
ok( "y" =~ m/(<<alpha>-[aeiou]>)/, "Named difference set match" );
ok( $1 eq 'y', "Named difference set capture" );
ok( "y" !~ m/(<[a-z]-[aeiou]-[y]>)/, "Multi-difference set failure" );
ok( "f" =~ m/(<[a-z]-[aeiou]-[y]>)/, "Multi-difference set match" );
ok( $1 eq 'f', "Multi-difference set capture" );

ok( ']' =~ m/(<[]]>)/, "LSB match" );
ok( $1 eq ']', "LSB capture" );
ok( ']' =~ m/(<[\]]>)/, "quoted close LSB match" );
ok( $1 eq ']', "quoted close LSB capture" );
ok( '[' =~ m/(<[\[]>)/, "quoted open LSB match" );
ok( $1 eq '[', "quoted open LSB capture" );
ok( '{' =~ m{(<[\{]>)}, "quoted open LCB match" );
ok( $1 eq '{', "quoted open LCB capture" );
