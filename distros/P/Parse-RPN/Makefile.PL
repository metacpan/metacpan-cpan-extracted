#!/usr/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
     NAME      => 'Parse::RPN',
     VERSION_FROM => 'lib/Parse/RPN.pm', # finds $VERSION
     ABSTRACT       => 'Parse::RPN Is a minimalist RPN parser/processor (a little like FORTH)',
             dist => { COMPRESS=>"gzip -f", SUFFIX=>"gz" },
     PREREQ_PM => { HTTP::Date=> 0,
                    PadWalker => 0 },
);
