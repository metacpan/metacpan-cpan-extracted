use strict;
use Test::More;
use Pandoc;

foreach (glob('xt/bin/*')) {
   next if $_ !~ qr{^xt/bin/pandoc-(\d(\.\d+)*)$};
   is(Pandoc->new($_)->version, $1, $1);
}

ok(1); # to avoid zero tests if no executables available

done_testing;
