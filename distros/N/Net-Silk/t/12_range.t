use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 3;

use Net::Silk qw( :basic );

BEGIN { use_ok( SILK_RANGE_CLASS ) }

sub make_range { SILK_RANGE_CLASS->new(@_) }

sub test_construction {

  plan tests => 24;

  my($r1, $r2);

  my $ip1 = '1.1.1.1';
  my $ip2 = '1.255.255.255';

        new_ok(SILK_RANGE_CLASS, [[$ip1, $ip2]]);
        new_ok(SILK_RANGE_CLASS, ["$ip1-$ip2"]);
  $r1 = new_ok(SILK_RANGE_CLASS, [$ip1, $ip2]);
  $r2 = new_ok(SILK_RANGE_CLASS, [$ip2, $ip1]);

  cmp_ok($r1->first,       'eq', $ip1,     "ip first");
  cmp_ok($r1->last,        'eq', $ip2,     "ip last");
  cmp_ok($r1->cardinality, '==', 16711423, "ip cardinality");

  cmp_ok($r1->first, 'eq', $r2->first, "ip first reverse");
  cmp_ok($r1->last,  'eq', $r2->last,  "ip last reverse");
  cmp_ok($r1->cardinality, 'eq', $r2->cardinality, "ip cardinality reverse");

  cmp_ok($r1, 'eq', $r2, "ip eq");
  cmp_ok($r1, '==', $r2, "ip ==");

  $r2 = make_range('2.2.2.2', '3.3.3.3');

  cmp_ok($r1, 'ne', $r2, "ip ne");
  cmp_ok($r1, '!=', $r2, "ip !=");

  my $pp1 = '6:80';
  my $pp2 = '6:443';

        new_ok(SILK_RANGE_CLASS, [[$pp1, $pp2]]);
        new_ok(SILK_RANGE_CLASS, ["$pp1-$pp2"]);
  $r1 = new_ok(SILK_RANGE_CLASS, [$pp1, $pp2]);
  $r2 = new_ok(SILK_RANGE_CLASS, [$pp2, $pp1]);

  cmp_ok($r1->first,       'eq', $pp1, "pp first");
  cmp_ok($r1->last,        'eq', $pp2, "pp last");
  cmp_ok($r1->cardinality, '==', 364,  "pp cardinality");

  cmp_ok($r1->first, 'eq', $r2->first, "pp first reverse");
  cmp_ok($r1->last,  'eq', $r2->last,  "pp last reverse");
  cmp_ok($r1->cardinality, 'eq', $r2->cardinality, "pp cardinality reverse");

}

sub test_sort {

  plan tests => 1;


  my @sorted = map { make_range($_) } (
    "1.2.3.4-5.6.7.8",
    "1.2.3.4-3.4.5.6",
    "2.3.4.5-6.7.8.9",
    "10.11.12.13-14.15.16.17",
  );

  my @result = sort reverse @sorted;

  is_deeply(\@result, \@sorted, "sort order");

}

sub test_all {
  subtest "construction" => \&test_construction;
  subtest "sort"         => \&test_sort;
}

test_all();
