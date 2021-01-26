#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Test Simd::Avx512
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2021
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Simd::Avx512;

Simd::Avx512::test();
