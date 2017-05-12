#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings;

use Test::More;

use lib 'lib';

eval 'use Test::Distribution not => [ qw/prereq podcover/ ]';   ## no critic
plan( skip_all => 'Test::Distribution not installed' ) if $@;
Test::Distribution->import(  );
