#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OPM::Maker;
use OPM::Maker::Command::build;

my $build = OPM::Maker::Command::build->new({
    app => OPM::Maker->new,
});

{
    my $return = $build->abstract;
    is $return, 'build package files for Znuny, OTOBO or ((OTRS)) Community Edition';
}

{
    my $return = $build->usage_desc;
    is $return, 'opmbuild build [--version <version>] [--basedir <output_path>] [--output <output_path>] <path_to_sopm>';
}

{
    my @return = $build->opt_spec;
    my $check  = [
        [ "output=s",  "Output path for OPM file" ],
        [ "basedir=s",  "Base directory of SOPM files" ],
        [ "version=s", "Version to be used (override the one from the sopm file)" ],
    ];
    is_deeply \@return, $check;
}

done_testing;
