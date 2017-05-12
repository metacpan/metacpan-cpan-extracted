#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;
use autodie;
use PIR;

my $rule = PIR->new->skip_dirs('.')->perl_module;

for ( $rule->all( { relative => 1 }, grep { /site_perl/ } @INC ) ) {
    s{[/\\]}{::}g;
    s{\.pm$}{};
    say;
}

