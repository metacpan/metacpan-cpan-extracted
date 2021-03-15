#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OPM::Maker;
use OPM::Maker::Command::index;

my $index = OPM::Maker::Command::index->new({
    app => OPM::Maker->new,
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
