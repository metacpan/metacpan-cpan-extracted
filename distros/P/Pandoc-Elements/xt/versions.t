use strict;
use Test::More;

use lib 'xt/lib';
use Pandoc::Releases;

foreach my $pandoc (pandoc_releases) {
    my $version = $pandoc->version;
    is $pandoc->bin, "xt/bin/$version/pandoc", $version;
}

done_testing;
