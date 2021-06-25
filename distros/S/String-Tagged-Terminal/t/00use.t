#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use_ok( "String::Tagged::Terminal" );
use_ok( "String::Tagged::Terminal::Win32Console" ) if $^O eq "MSWin32";

done_testing;
