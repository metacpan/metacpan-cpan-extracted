#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OPM::Maker;
use OPM::Maker::Command::filetest;

my $filetest = OPM::Maker::Command::filetest->new({
    app => OPM::Maker->new,
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
