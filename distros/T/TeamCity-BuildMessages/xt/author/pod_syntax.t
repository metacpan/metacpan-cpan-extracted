#!/usr/bin/env perl

use 5.008004;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v0.999.3');

use Test::More;
use Test::Pod;

all_pod_files_ok();

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
