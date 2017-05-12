use Perl6::Rules;
use Test::Simple 'no_plan';

$str = "abcabcabc";
ok( $str =~ m:c/abc/, "Continued match" );
ok( pos($str) == 3, "Continued match pos" );

$str = "abcabcabc";
$x = $str =~ m:ic/abc/;
ok( pos($str) == 3, "Insensitive continued match pos" );

$x = $str =~ m:ic/abc/;
ok( pos($str) == 6, "Insensitive recontinued match pos" );

$str = "abcabcabc";
@x = $str =~ m:igc/abc/;
ok( "@x" eq "abc abc abc", "Insensitive repeated continued match" );
ok( pos($str) == 9, "Insensitive repeated continued match pos" );

$str = "abcabcabc";
@x = scalar $str =~ m:cig/abc/;
ok( pos($str) == 3, "Insensitive scalar repeated continued match pos" );


