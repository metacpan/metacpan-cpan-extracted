#! /usr/bin/perl

use strict;
use warnings;

use FindBin;
use ExtUtils::MakeMaker;
use Test::More tests => 1;

isnt(MM->parse_version(
    "$FindBin::Bin/../lib/Parse/CPAN/Cached.pm"),
    'undef',
    '$VERSION defined'
);
