#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OPM::Maker;
use OPM::Maker::Command::dependencies;

my $dependencies = OPM::Maker::Command::dependencies->new({
    app => OPM::Maker->new,
});

{
    my $return = $dependencies->abstract;
    is $return, 'list dependencies for OPM packages';
}

{
    my $return = $dependencies->usage_desc;
    is $return, 'opmbuild dependencies <path_to_sopm_or_opm>';
}

done_testing;
