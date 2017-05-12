#!/usr/bin/env perl
#
# Statistics::Discrete
#
# Chiara Orsini, CAIDA, UC San Diego
# chiara@caida.org
#
# Copyright (C) 2014 The Regents of the University of California.
#
# Statistics::Discrete is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Statistics::Discrete is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Statistics::Discrete.  If not, see <http://www.gnu.org/licenses/>.
#


use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Statistics::Discrete',
    VERSION_FROM      => 'lib/Statistics/Discrete.pm', 
    PREREQ_PM         => { 'List::Util' => 1.25,
			   'Storable' => 2.41}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'Perl extension for statistical analyses of discrete data',
       AUTHOR         => 'Chiara Orsini <chiara@caida.org>') : ()),
);
