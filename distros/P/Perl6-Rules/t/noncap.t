use Perl6::Rules;
use Test::Simple 'no_plan';

$str = "abbbbbbbbc";

ok( $str =~ m{a(b+)c}, "Matched 1");
ok( $0, "Saved 1");
ok( $0->[0] eq $str, "Grabbed all 1");
ok( $0->[1] eq substr($str,1,-1), "Correctly captured 1");

ok( $str =~ m{a[b+]c}, "Matched 2");
ok( $0, "Saved 2");
ok( $0->[0] eq $str, "Grabbed all 2");
ok( !defined $0->[1], "Correctly didn't capture 2");
