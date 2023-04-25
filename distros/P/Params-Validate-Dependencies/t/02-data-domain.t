use strict;
use warnings;

use Test::More (
    $] <= 5.018 ? (skip_all => 'only on perl 5.18 and higher') : ()
);
END { done_testing(); }

use Data::Domain qw(:all);
use Data::Domain::Dependencies qw(:all);

my $domain = Int(-min => 3, -max => 7);

ok(!$domain->inspect(4), "normal Data::Domain stuff works");
ok($domain->inspect(8), "normal Data::Domain stuff works");
ok($domain->inspect(2), "normal Data::Domain stuff works");

$domain = Dependencies(
  any_of(
    qw(alpha beta),
    all_of(qw(foo bar))
  )
);

ok($domain->inspect({}), "D::D::P fails correctly with empty hash");
ok($domain->inspect({foo => 1}), "D::D::P fails embedded code-ref");
ok($domain->inspect({gamma => 1}), "D::D::P fails correctly scalar");
ok(!$domain->inspect({alpha => 1}), "D::D::P passes correctly scalar");
ok(!$domain->inspect({foo => 1, bar => 1}), "D::D::P passes correctly embedded code-ref");
