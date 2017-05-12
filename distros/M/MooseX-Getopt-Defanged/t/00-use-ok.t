#!/usr/bin/env perl

use 5.010;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v1.18.0');


use Test::More;
use Test::Compile;

all_pm_files_ok() or BAIL_OUT('No point in continuing.');

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 autoindent :
# setup vim: set foldmethod=indent foldlevel=0 fileencoding=utf8 :
