#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "String::Tagged::Terminal" );
use_ok( "String::Tagged::Terminal::Win32Console" ) if $^O eq "MSWin32";

done_testing;
