#!/usr/bin/perl -I/home/phil/perl/cpan/NasmX86/lib
#-------------------------------------------------------------------------------
# Test Nasm:X86
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Nasm::X86;

Nasm::X86::test();
