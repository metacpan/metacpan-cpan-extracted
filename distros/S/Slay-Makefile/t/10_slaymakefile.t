#!/usr/local/bin/perl

use FindBin;

use lib (
    "$FindBin::RealBin",
    "$FindBin::RealBin/10_slaymakefile.dir", # for trace.pm
);
use runtests;

do_tests;
