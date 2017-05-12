use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 3;

use Net::Silk qw( :basic );

BEGIN { use_ok( SILK_CIDR_CLASS ) }

sub make_cidr { SILK_CIDR_CLASS->new(@_) }

sub test_construction {

  plan tests => 10;

  my($c1, $c2);

  my $ip1     = '1.1.1.0';
  my $prefix1 = 27;
  my $ip2     = '1.1.1.0';
  my $prefix2 = 25;

        new_ok(SILK_CIDR_CLASS, [[$ip1, $prefix1]]);
        new_ok(SILK_CIDR_CLASS, ["$ip1/$prefix1"]);
  $c1 = new_ok(SILK_CIDR_CLASS, [$ip1, $prefix1]);

  cmp_ok($c1->ip,          'eq', $ip1,     "ip");
  cmp_ok($c1->prefix,      'eq', $prefix1, "prefix");
  cmp_ok($c1->cardinality, '==', 32,       "cardinality");

  $c2 = make_cidr($ip1, $prefix1);

  cmp_ok($c1, 'eq', $c2, "eq");
  cmp_ok($c1, '==', $c2, "==");

  $c2 = make_cidr($ip2, $prefix2);

  cmp_ok($c1, 'ne', $c2, "ne");
  cmp_ok($c1, '!=', $c2, "!=");

}

sub test_sort {

  plan tests => 1;

  my @sorted = map { make_cidr($_) } (
    "1.2.3.0/25",
    "1.2.3.0/27",
    "5.6.7.0/25",
    "5.6.7.0/27",
  );

  my @result = sort reverse @sorted;

  is_deeply(\@result, \@sorted, "sort order");

}

sub test_all {
  subtest "construction" => \&test_construction;
  subtest "sort"         => \&test_sort;
}

test_all();
