

use strict;
use warnings;
use lib qw(../lib);
use Test::More tests =>1;
use Data::Dumper;
use Net::IP::RangeCompare qw(:ALL);
our $p='Net::IP::RangeCompare';

# next cidr tests
{
  my $range=$p->new(6,8);
  my ($first,$notation,$next)=$range->get_first_cidr;
  $next=$range;
  my $test=0;
  while($next) {
    ($first,$notation,$next)=$next->get_first_cidr;
    ++$test;
  }
  ok(2==$test,'should have 2 rows');
}
