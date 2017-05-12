#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/lib";
use tools;

diag("\e[31mLast 1000 lines of cpanm build log\e[0m");
safe_exec( 'tail', '-n', '1000', $ENV{HOME} . '/.cpanm/build.log' );

