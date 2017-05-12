# This -*-perl-*- script writes the Makefile for installing this distribution.
#
# See "perldoc perlmodinstall" or "perldoc ExtUtils::MakeMaker" for
# info on how to control how the installation goes.
#
#                                       Time-stamp: "2004-12-29 20:40:11 AST"

require 5.004;
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Pod::PXML',
    'VERSION_FROM' => 'lib/Pod/PXML.pm', # finds $VERSION
    'EXE_FILES' => [qw(pod2pxml pxml2pod)],
    'PREREQ_PM' => {
		    'Pod::Tree' => 1.06,
		    'Pod::Text' => 2.09,
		    'HTML::Entities' => 1,
		    'XML::Parser' => 2,
		   },
    'dist'        => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);
