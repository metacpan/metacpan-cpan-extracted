#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Pod::Abstract;

my @try_files = qw(
lib/Pod/Abstract.pm
lib/Pod/Abstract/Node.pm
lib/Pod/Abstract/Filter.pm
bin/paf
);

local $/ = undef;

foreach my $file (@try_files) {
    open IN, "<lib/Pod/Abstract.pm";
    my $pa_text = <IN>;
    my $pa = Pod::Abstract->load_string($pa_text);

    ok($pa, "$file parsed OK");
    ok($pa_text eq $pa->pod, "Document round-trip with no changes");
}

1;
