#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/..";


use Test::More tests => 1;
use t::ChkUtil;
dualvar_or_skip 1;
use_ok('PostScript::PPD');

