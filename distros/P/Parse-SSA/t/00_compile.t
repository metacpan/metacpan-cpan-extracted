use strict;
use Test::More tests => 1;

BEGIN { use_ok('Parse::SSA') };

my @files = ("t/data/test.ass");

for my $file (@files) {

    my $sub = Parse::SSA->new($file);
    my $row = $sub->subrow();
}

