#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib', 't/lib';
use Test::More tests => 2;
use Slow::Loading::Module;
ok 1, 'slow loading module loaded';

ok !exists $ENV{aggregated_current_script},
  'env variables should not hang around';
$ENV{aggregated_current_script} = $0;
