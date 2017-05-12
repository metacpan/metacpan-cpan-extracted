#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Term::Filter::Callback;

my ($input, $output);
open my $infh, '<', \$input or die "Couldn't open: $!";
open my $outfh, '<', \$output or die "Couldn't open: $!";
like(
    exception { Term::Filter::Callback->new(input => $infh) },
    qr/Term::Filter requires input and output filehandles to be attached to a terminal/,
    "requires a terminal"
);
like(
    exception { Term::Filter::Callback->new(output => $outfh) },
    qr/Term::Filter requires input and output filehandles to be attached to a terminal/,
    "requires a terminal"
);

done_testing;
