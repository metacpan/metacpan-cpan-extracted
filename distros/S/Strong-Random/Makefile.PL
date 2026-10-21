#!/usr/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Strong::Random',
    VERSION_FROM  => "lib/Strong/Random.pm",
    AUTHOR        => 'Ivan Trunaev',
    PREREQ_PM     => {'Rand::Urandom' => '0.03'},
);

1;
