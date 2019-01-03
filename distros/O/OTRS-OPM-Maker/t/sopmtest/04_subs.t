#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OTRS::OPM::Maker;
use OTRS::OPM::Maker::Command::sopmtest;

my $sopmtest = OTRS::OPM::Maker::Command::sopmtest->new({
    app => OTRS::OPM::Maker->new,
});

{
    my $return = $sopmtest->abstract;
    is $return, 'check .sopm if it is valid';
}

{
    my $return = $sopmtest->usage_desc;
    is $return, 'opmbuild sopmtest <path_to_sopm>';
}

done_testing;
