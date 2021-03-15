#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OPM::Maker;
use OPM::Maker::Command::dbtest;

my $dbtest = OPM::Maker::Command::dbtest->new({
    app => OPM::Maker->new,
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
