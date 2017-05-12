#!/usr/bin/env perl

# Taken from
# http://www.chrisdolan.net/talk/index.php/2005/11/14/private-regression-tests/.

use 5.008004;
use utf8;

use strict;
use warnings;

use version; our $VERSION = qv('v0.999.3');

# No POD coverage due to complaints about builtins when using Fatal.
use Test::Distribution ( distversion => 1, not => 'podcover' );

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
