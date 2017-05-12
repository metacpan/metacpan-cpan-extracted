#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use lib 'lib';

use Test::More;

eval 'use Test::PureASCII';  ## no critic
plan skip_all => 'Test::PureASCII required to criticise code' if $@;

all_perl_files_are_pure_ascii();
