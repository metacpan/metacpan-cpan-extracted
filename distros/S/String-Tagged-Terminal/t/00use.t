#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require String::Tagged::Terminal;
require String::Tagged::Terminal::Win32Console if $^O eq "MSWin32";

pass "Modules loaded";
done_testing;
