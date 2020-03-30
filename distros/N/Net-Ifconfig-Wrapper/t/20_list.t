
use warnings;
use strict;

use Data::Dumper;
use Test::More;

use blib;

use Net::Ifconfig::Wrapper qw( Ifconfig );

my $sSkip = q//;
my $rh = Ifconfig('list');
if ($@ =~ m'/sbin/ifconfig: not found')
  {
  $sSkip = "/sbin/ifconfig is not available on this system; skipping content-based tests";
  diag $sSkip;
  # BAIL_OUT;
  } # if
subtest 'skippable' => sub {
  if ($sSkip ne q//)
    {
    plan skip_all => $sSkip;
    }
  else
    {
    isa_ok($rh, 'HASH');
    # warn Dumper($rh);
    my @a = keys %$rh;
    my $iCount = scalar @a;
    diag "found $iCount adapters";
    cmp_ok(1, '<=', $iCount, 'at least one adapter found');
    } # else
  } # skippable
;
done_testing();

__END__
