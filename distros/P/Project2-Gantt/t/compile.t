use strict;
use warnings;
use Test::More;

use File::Find::Rule;

my @files = File::Find::Rule->name('*.pm')->in('lib');

plan tests => scalar @files;

for (@files) {
    s/^lib.//;
    s/.pm$//;
    s{[\\/]}{::}g;
    diag $_;
    require_ok($_);
}

