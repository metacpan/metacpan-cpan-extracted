# generate Makefile for building String::FixedLen;
#
# Copyright (C) 2007 David Landgren

use strict;
use ExtUtils::MakeMaker;

eval "use ExtUtils::MakeMaker::Coverage";
$@ or print "Adding testcover target\n";

WriteMakefile(
    NAME          => 'String::FixedLen',
    VERSION_FROM  => 'FixedLen.pm',
    ABSTRACT_FROM => 'FixedLen.pm',
    AUTHOR        => 'David Landgren',
    LICENSE       => 'perl',
);
