#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OTRS::OPM::Maker;
use OTRS::OPM::Maker::Command::index;

my $index = OTRS::OPM::Maker::Command::index->new({
    app => OTRS::OPM::Maker->new,
});

{
    my $return = $index->abstract;
    is $return, 'build index for an OPM repository';
}

{
    my $return = $index->usage_desc;
    is $return, 'opmbuild index <path_to_directory>';
}

done_testing;
