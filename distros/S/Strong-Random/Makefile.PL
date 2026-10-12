#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Strong::Random',
    VERSION_FROM  => "lib/Strong/Random.pm",
    AUTHOR        => q{Ivan Trunaev},
);

1;
