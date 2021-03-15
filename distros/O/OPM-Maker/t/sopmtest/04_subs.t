#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OPM::Maker;
use OPM::Maker::Command::sopmtest;

my $sopmtest = OPM::Maker::Command::sopmtest->new({
    app => OPM::Maker->new,
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
