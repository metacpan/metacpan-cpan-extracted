#!/usr/bin/env perl
use strictures 2;

my $iters = 10_000;

use Devel::NYTProf;

use Starch;

my $starch = Starch->new(
    store => { class=>'::Memory' },
);
#my $starch = Starch->new_plugins(
#    plugins => ['::Sereal'],
#    store => { class=>'::Memory' },
#);

foreach (1..$iters) {
    my $state = $starch->state();

    $state->data->{foo} = 32;

    if ($state->data->{bar}) { ... }

    $state->save();

    $state = $starch->state( $state->id() );

    if ($state->data->{bar}) { ... }

    $state->save();

    $state = $starch->state( $state->id() );
}
