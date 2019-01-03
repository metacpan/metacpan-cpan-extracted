#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OTRS::OPM::Maker;
use OTRS::OPM::Maker::Command::filetest;

my $filetest = OTRS::OPM::Maker::Command::filetest->new({
    app => OTRS::OPM::Maker->new,
});

{
    my $return = $filetest->abstract;
    is $return, 'Check if filelist in .sopm includes the files on your disk';
}

{
    my $return = $filetest->usage_desc;
    is $return, 'opmbuild filetest <path_to_sopm>';
}

done_testing;
