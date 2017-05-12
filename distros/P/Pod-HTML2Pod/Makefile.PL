# This -*-perl-*- script writes the Makefile for installing this distribution.
#
# See "perldoc perlmodinstall" or "perldoc ExtUtils::MakeMaker" for
# info on how to control how the installation goes.
#
#                                       Time-stamp: "2004-12-29 20:19:19 AST"

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Pod::HTML2Pod',
    'VERSION_FROM' => 'lib/Pod/HTML2Pod.pm', # finds $VERSION
    'EXE_FILES' => [qw(html2pod)],
    'dist'        => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
    'PREREQ_PM'    => {	
                         # Yes, a lot of prereqs:
	                 'HTML::Entities' => 0, # don't check version
	                 'HTML::Tagset' => 3.02,
	                 'HTML::TreeBuilder' => 3.05,
                           # probably requires HTML::Parser
	                 'HTML::Element' => 3.05,
                         'Carp' => 0, # don't check version
                         'UNIVERSAL' => 0, # don't check version
                         'integer' => 0, # don't check version
		      },
);
