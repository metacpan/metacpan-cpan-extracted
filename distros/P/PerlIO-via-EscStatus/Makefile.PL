#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of PerlIO-via-EscStatus.
#
# PerlIO-via-EscStatus is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# PerlIO-via-EscStatus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with PerlIO-via-EscStatus.  If not, see <http://www.gnu.org/licenses/>.


# 5.8.5 for unicode properties ...
# otherwise 5.8.1 for utf8::is_utf8
use 5.008005;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'PerlIO-via-EscStatus',
   ABSTRACT     => 'Printing a status line through an I/O layer.',
   VERSION_FROM => 'lib/PerlIO/via/EscStatus.pm',
   PREREQ_PM    => {
                    # "via" is builtin in perl 5.8, dunno if it can work
                    # before that anyway
                    'PerlIO::via' => 0,

                    'Regexp::Common' => 0,
                    'Regexp::Common::ANSIescape' => 11, # v.11 separate
                    'Term::Size' => 0,
                    'Encode' => 0,
                   },
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.008005',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/perlio-via-escstatus/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel'] },

     optional_features =>
     { maximum_interoperation =>
       { description => 'Have maximum inter-operation with other modules (optional supported other stuff).',
         requires => { 'ProgressMonitor' => 0 },
       },

       maximum_examples =>
       { description => 'Be able to run all the example programs.',
         requires => { 'ProgressMonitor' => 0,
                       'Term::Sk' => 0,
                       # 'Time::HiRes' => 0,     # with 5.8 already
                       # 'Term::ANSIColor' => 0, # with 5.6 already
                       # 'charnames' => 0,       # with 5.6 already
                     }
       },
     },
   },
  );

# maximum_devel =>
# { description => 'Stuff used variously for development.',
#   requires => { 'Devel::TraceLoad' => 0,
#                 'charnames' => 0,
#                 'Devel::FindRef' => 0,
#                 'Term::Sk' => 0,
#               },
# },
