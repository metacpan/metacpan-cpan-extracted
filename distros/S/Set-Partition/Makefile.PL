# generate Makefile for building Set::Partition
#
# Copyright (C) 2006 David Landgren

use strict;
use ExtUtils::MakeMaker;

eval "use ExtUtils::MakeMaker::Coverage";
if( $@ ) {
    print "Can't load ExtUtils::MakeMaker::Coverage, not adding testcover target\n";
}
else {
    print "Adding testcover target\n";
}

WriteMakefile(
    NAME          => 'Set::Partition',
    VERSION_FROM  => 'Partition.pm',
    ABSTRACT_FROM => 'Partition.pm',
    AUTHOR        => 'David Landgren',
    LICENSE       => 'perl',
);
