use strict;
use warnings;

use Test::More (
    $] <= 5.010 ? (skip_all => 'only on perl 5.10 and higher') : ()
);

use Data::Domain::Dependencies qw(Dependencies);
use Params::Validate::Dependencies::all_or_none_of;

my $domain = Dependencies(
  all_or_none_of(qw(alpha beta gamma))
);

foreach my $one (qw(alpha beta gamma)) {
  my @two = grep { $_ ne $one } qw(alpha beta gamma);
  ok($domain->inspect({$one => 1}), "only one ($one) of three, validation failed");
  ok($domain->inspect({$two[0] => 1, $two[1] => 1}),
    "only two (".join(', ', @two).") of three, validation failed")
}

ok(!$domain->inspect({}), "none, validation succeeded");
ok(!$domain->inspect({map { $_ => 1 } qw(alpha beta gamma)}), "all three, validation succeeded");

done_testing();
