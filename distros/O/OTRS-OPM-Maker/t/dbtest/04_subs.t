#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OTRS::OPM::Maker;
use OTRS::OPM::Maker::Command::dbtest;

my $dbtest = OTRS::OPM::Maker::Command::dbtest->new({
    app => OTRS::OPM::Maker->new,
});

{
    my $return = $dbtest->abstract;
    is $return, 'Check if DatabaseInstall and DatabaseUninstall sections in the .sopm are correct';
}

{
    my $return = $dbtest->usage_desc;
    is $return, 'opmbuild dbtest <path_to_sopm>';
}

done_testing;
