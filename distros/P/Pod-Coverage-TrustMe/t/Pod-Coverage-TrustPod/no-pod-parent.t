use strict;
use warnings;
use Test::More;

use lib 't/Pod-Coverage-TrustPod/lib';

use Pod::Coverage::TrustMe;
my $PC = 'Pod::Coverage::TrustMe';

my $ok = eval {
  {
    my $obj = $PC->new( package => 'ChildWithPod' );
    if (! defined $obj->coverage) {
      diag "no coverage: " . $obj->why_unrated;
      die;
    }
  }

  return 1;
};

is($@, '', "expected to live (no error)");
ok($ok, 'expecting to live');

done_testing;
