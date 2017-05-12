package t::Utils;
use strict;
use warnings;
use utf8;
use Test::FailWarnings;
use Test::Name::FromLine;

sub import {
    strict->import;
    warnings->import;
    utf8->import;
}

1;
