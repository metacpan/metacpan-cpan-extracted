#!/usr/bin/env perl

use 5.008003;
use utf8;
use strict;
use warnings;

use Test::More tests => 1;

use_ok('Module::Used') or BAIL_OUT('No point in continuing.');

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
