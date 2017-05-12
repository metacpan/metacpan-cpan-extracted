#!/usr/bin/env perl

use strict;
use warnings;

use t::AllTests;

t::PBS::set_global_warp_mode('1.5');
Test::Class->runtests;
