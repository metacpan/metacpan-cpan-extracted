#!perl -w

use strict;
use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 1) : (skip_all => 'require Test::LeakTrace');
use Test::LeakTrace;

use Set::Object qw(set);
use Scalar::Util qw(weaken);

leaks_cmp_ok{
  my $set = set();
  $set->insert({ "hi" => "there" });
  my $internal = $set->get_flat;
  $set->insert(1, 2, 3, 4);
  $internal = $set->get_flat;
  weaken($internal);
  $set->insert(5);
} '<', 1;
