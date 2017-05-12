use strict;
use Test::More;
use File::Basename;

use lib 'xt/lib';
use Pandoc::Releases;

my $PATH = $ENV{PATH};

foreach my $pandoc (pandoc_releases) {
    note $pandoc->bin;
    local $ENV{PATH} = dirname($pandoc->bin).":$PATH";
    system 'perl -Ilib script/pod2pandoc script/pod2pandoc -o tmp.md';
}

done_testing;
