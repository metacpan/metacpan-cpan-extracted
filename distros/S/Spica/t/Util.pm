package t::Util;
use strict;
use warnings;
use utf8;

sub import {
    strict->import;
    warnings->import;
    utf8->import;
}

1;
