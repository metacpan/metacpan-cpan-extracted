#!perl -w
$|++;

use strict;
use Test::More tests => 958;

use lib "./t";
use _nrr_test_util;

use lib "./blib/lib";
use Number::Range::Regex;

# test the code from the perldoc and some variations thereon
my $lt_20    = range( 0, 19 );
ok($lt_20);
my $lt_20_re = $lt_20->regex();
ok($lt_20_re);
ok( "the number is 17 and the color is orange" =~ /($lt_20_re)/ );
ok(1 == $1); # 1/7/17 - re engine chooses first it sees, which is "1"
ok( "the number is 17 and the color is orange" =~ /($lt_20)/ );
ok(1 == $1); # 1/7/17 - re engine chooses first it sees, which is "1"
ok( "the number is 7 and the color is orange" =~ /($lt_20_re)/ );
ok(7 == $1);
ok( "the number is 7 and the color is orange" =~ /($lt_20)/ );
ok(7 == $1);
ok( "the number is 17 and the color is orange" !~ /^($lt_20_re)$/ );
ok( "the number is 17 and the color is orange" !~ /^($lt_20)$/ );
for my $c (0..19) {
  ok( $c =~ /$lt_20/ );
  ok( $c =~ /^($lt_20)$/ );
  ok( $c == $1 );
  ok( $c =~ /$lt_20_re/ );
  ok( $c =~ /^($lt_20_re)$/ );
  ok( $c == $1 );
}
ok(-1 !~ /^$lt_20_re$/);
ok(20 !~ /^$lt_20_re$/);
ok(-1 !~ /^$lt_20$/);
ok(20 !~ /^$lt_20$/);
ok( "field1 17 rest of line" =~ /^\S+\s+($lt_20_re)\s/ );
ok($1 == 17);
ok( "field1 17 rest of line" =~ /^\S+\s+($lt_20)\s/ );
ok($1 == 17);
my $nice_numbers = rangespec( "42,175..192" );
my $my_values = $lt_20->union( $nice_numbers );
my $my_values_re = $my_values->regex;
my $line = "field1 42 rest of line";
ok( $line =~ /^\S+\s+($my_values_re)\s/ );
ok($1 == 42);
ok( $line =~ /^\S+\s+($my_values)\s/ );
ok($1 == 42);

my $lt_10        = rangespec( "0..9" );
ok($lt_10);
my $primes_lt_30 = rangespec( "2,3,5,7,11,13,17,19,23,29" );
ok($primes_lt_30);
my $primes_lt_10 = $lt_10->intersection( $primes_lt_30 );
ok($primes_lt_10);
my $primes_lt_10_re = $primes_lt_10->regex;
ok($primes_lt_10_re);
ok( /^$primes_lt_10_re$/ ) for (2,3,5,7);
ok( !/^$primes_lt_10_re$/ ) for (0,1,4,6,8,9);
ok( /^$primes_lt_10$/ ) for (2,3,5,7);
ok( !/^$primes_lt_10$/ ) for (0,1,4,6,8,9);
ok( $primes_lt_10->contains($_) ) for (2,3,5,7);
ok( !$primes_lt_10->contains($_) ) for (0,1,4,6,8,9);
my $nonprimes_lt_10 = $lt_10->minus( $primes_lt_30 );
ok($nonprimes_lt_10);
my $nonprimes_lt_10_re = $nonprimes_lt_10->regex;
ok($nonprimes_lt_10_re);
ok( !/^$nonprimes_lt_10_re$/ ) for (2,3,5,7);
ok( /^$nonprimes_lt_10_re$/ ) for (0,1,4,6,8,9);
ok( !/^$nonprimes_lt_10$/ ) for (2,3,5,7);
ok( /^$nonprimes_lt_10$/ ) for (0,1,4,6,8,9);
ok( !$nonprimes_lt_10->contains($_) ) for (2,3,5,7);
ok( $nonprimes_lt_10->contains($_) ) for (0,1,4,6,8,9);

my $octet = range(0, 255);
ok($octet);
my $octet_re = $octet->regex;
ok($octet_re);
ok( /^$octet_re$/ ) for (0..255);
ok( /^$octet$/ ) for (0..255);
my $ip4_match = qr/^$octet_re\.$octet_re\.$octet_re\.$octet_re$/;
ok($ip4_match);
ok( /^$ip4_match$/ ) for ("1.2.3.4", "74.125.228.5", "173.203.36.104" );
ok( !/^$ip4_match$/ ) for ("256.2.3.4", "1.256.3.4", "1.2.256.4", "1.2.3.256");
ok( !/^$ip4_match$/ ) for ("-1.2.3.4", "1.-1.3.4", "1.2.-1.4", "1.2.3.-1");
my $ip4_match2 = qr/^$octet\.$octet\.$octet\.$octet$/;
ok($ip4_match2);
ok( /^$ip4_match2$/ ) for ("1.2.3.4", "74.125.228.5", "173.203.36.104" );
ok( !/^$ip4_match2$/ ) for ("256.2.3.4", "1.256.3.4", "1.2.256.4", "1.2.3.256");
ok( !/^$ip4_match2$/ ) for ("-1.2.3.4", "1.-1.3.4", "1.2.-1.4", "1.2.3.-1");
my $range_96_to_127 = range(96, 127);
ok($range_96_to_127);
my $re_96_to_127 = $range_96_to_127->regex;
ok($re_96_to_127);
ok( /^$re_96_to_127$/ ) for (96..127);
ok( !/^$re_96_to_127$/ ) for (95,128);
ok( /^$range_96_to_127$/ ) for (96..127);
ok( !/^$range_96_to_127$/ ) for (95,128);
my $my_slash26_match = qr/^192\.168\.42\.$re_96_to_127$/;
ok($my_slash26_match);
ok( /^$my_slash26_match$/ ) for map { "192.168.42.$_" } ( 96..127 );
ok( !/^$my_slash26_match$/ ) for map { "192.168.42.$_" } ( 95,128 );
my $my_slash26_match2 = qr/^192\.168\.42\.$range_96_to_127$/;
ok($my_slash26_match2);
ok( /^$my_slash26_match2$/ ) for map { "192.168.42.$_" } ( 96..127 );
ok( !/^$my_slash26_match2$/ ) for map { "192.168.42.$_" } ( 95,128 );
my $my_slash19_match = qr/^192\.168\.$re_96_to_127\.$octet_re$/;
ok($my_slash19_match);
ok( /^$my_slash19_match$/ ) for map { "192.168.$_.".int rand 255 } ( 96..127 );
ok( !/^$my_slash19_match$/ ) for map { "192.168.$_.".int rand 255 } ( 95,128 );
my $my_slash19_match2 = qr/^192\.168\.$range_96_to_127\.$octet$/;
ok($my_slash19_match2);
ok( /^$my_slash19_match2$/ ) for map { "192.168.$_.".int rand 255 } ( 96..127 );
ok( !/^$my_slash19_match2$/ ) for map { "192.168.$_.".int rand 255 } ( 95,128 );

