#!/usr/bin/perl -w

# Copyright 2012, 2014, 2015 Kevin Ryde

# This file is part of Regexp-Common-Other.
#
# Regexp-Common-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Regexp-Common-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Regexp-Common-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME          => 'Regexp::Common::Other',
   ABSTRACT      => 'Some more Regexp::Common patterns.',
   VERSION_FROM  => 'lib/Regexp/Common/ANSIescape.pm',
   PREREQ_PM     => {
                     'Regexp::Common' => 0,
                    },
   TEST_REQUIRES => {
                     'Test' => 0,
                     'Data::Dumper' => 0,
                    },
   AUTHOR        => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE       => 'gpl_3',
   SIGN          => 1,
   MIN_PERL_VERSION => '5.005', # same as Regexp::Common

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     no_index    => { directory=>['devel','xt'] },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/regexp-common-other/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },

     # Regexp::Common::Other gets the dist name, no actual module of that name
     provides =>
     { 'Regexp::Common::Other'      => { file => 'META.yml',
                                         version => 14,
                                       },
       'Regexp::Common::ANSIescape' => { file => 'lib/Regexp/Common/ANSIescape.pm',
                                         version => 14,
                                       },
       'Regexp::Common::Emacs'      => { file => 'lib/Regexp/Common/Emacs.pm',
                                         version => 14,
                                       },
     },
   },
  );

exit 0;
