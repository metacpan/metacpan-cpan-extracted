#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OTRS::OPM::Maker;
use OTRS::OPM::Maker::Command::dependencies;

my $dependencies = OTRS::OPM::Maker::Command::dependencies->new({
    app => OTRS::OPM::Maker->new,
});

{
    my $return = $dependencies->abstract;
    is $return, 'list dependencies for OTRS packages';
}

{
    my $return = $dependencies->usage_desc;
    is $return, 'opmbuild dependencies <path_to_sopm_or_opm>';
}

done_testing;
