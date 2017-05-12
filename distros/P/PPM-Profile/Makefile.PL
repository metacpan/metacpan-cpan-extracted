#!/usr/bin/env perl
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME   => 'PPM::Profile',
              AUTHOR => 'Philippe M. Chiasson <gozer@ActiveState.com>',
              VERSION_FROM => 'lib/PPM/Profile.pm',
              ABSTRACT     => 'A tool to save and restore PPM profiles',
              EXE_FILES    => [glob('bin/*')],
	      (MM->can('signature_target') ? (SIGN => 1) : ()),
              PREREQ_PM    => {
                            'Getopt::Long' => 0,
                            'File::Temp'   => 0,
                            'XML::Simple'  => 0,
                            'Pod::Usage'   => 0,
                           },
             );
