#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2014 Kevin Ryde

# This file is part of POSIX-Wide.
#
# POSIX-Wide is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# POSIX-Wide is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with POSIX-Wide.  If not, see <http://www.gnu.org/licenses/>.

use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'POSIX::Wide',
   ABSTRACT     => 'POSIX functions with wide-char strings.',
   VERSION_FROM => 'lib/POSIX/Wide.pm',
   PREREQ_PM    => {
                    # version 2.25 for Encode::Alias recognise "646" on netbsd
                    'Encode' => '2.25',

                    'Encode::Locale' => 0,
                   },
   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   MIN_PERL_VERSION => 5.008001,

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/posix-wide/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },
   },
  );
