#!/usr/bin/perl

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Pod-MinimumVersion.
#
# Pod-MinimumVersion is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Pod-MinimumVersion is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Pod-MinimumVersion',
   ABSTRACT     => 'Determine minimum Perl version of POD directives.',
   VERSION_FROM => 'lib/Pod/MinimumVersion.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   EXE_FILES    => [ 'pod-minimumversion' ],

   PREREQ_PM    => {
                    # 1.02 for avoiding leaks in perl 5.8, probably
                    # something newer has more merit though
                    'IO::String' => '1.02',

                    'List::Util' => 0,
                    'Pod::Parser' => 0,
                    'version' => 0,

                    # only for testing ...
                    'Test' => 0,
                   },
   # but Pod::Parser, IO::String and version.pm are all 5.005 though ...
   MIN_PERL_VERSION => '5.004',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/pod-minimumversion/index.html',
     },
     optional_features =>
     {
      # maximum_tests =>
      # { description => 'Have "make test" do as much as possible.',
      #   requires => { # Test::Weaken 2.002 for "ignore"
      #                'Test::Weaken' => '2.002',
      #               },
      # },
      maximum_devel =>
      { description => 'Stuff used variously for development.',
        requires => { 'Smart::Comments'     => 0,
                    },
      },
     },
   },
  );
