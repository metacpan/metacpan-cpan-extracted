use strict;
use Test::More;
use Pandoc;

foreach (glob('xt/bin/*')) {
   next if $_ !~ qr{^xt/bin/pandoc-(\d(\.\d+)*)$};
   is(Pandoc->new($_)->version, $1, $1);
}

done_testing;
