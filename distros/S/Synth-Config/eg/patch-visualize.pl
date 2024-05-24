#!/usr/bin/env perl
use strict;
use warnings;

use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(Synth-Config); # local author libs
use Synth::Config ();
use Getopt::Long qw(GetOptions);

my %opt = (
    model => undef, # e.g. 'Modular'
    patch => undef, # e.g. 'Simple 001'
);
GetOptions(\%opt,
    'model=s',
    'patch=s@',
);

my $model = $opt{model};

die "Usage: perl $0 --model='Modular' [--patch='Simple 001' --patch='Simple 002']\n"
    unless $model;

my $synth = Synth::Config->new(
    model => $model,
#    verbose => 1,
);

my @patches = $opt{patch} ? $opt{patch}->@* : $synth->recall_names;

for my $patch_name (@patches) {
    my $settings = $synth->search_settings(name => $patch_name);
    $synth->graphviz(
        settings   => $settings,
        model_name => $model,
        render     => 1,
    );
}
