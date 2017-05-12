##
##  String::Divert - String Object supporting Folding and Diversion
##  Copyright (c) 2003-2005 Ralf S. Engelschall <rse@engelschall.com>
##
##  This file is part of String::Divert, a Perl module providing
##  a string object supporting folding and diversion.
##
##  This program is free software; you can redistribute it and/or
##  modify it under the terms of the GNU General Public  License
##  as published by the Free Software Foundation; either version
##  2.0 of the License, or (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this file; if not, write to the Free Software Foundation,
##  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
##
##  Makefile.PL: Module Build Specification
##

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'String::Divert',
    VERSION_FROM  => 'Divert.pm',
    ABSTRACT      => 'String Object supporting Folding and Diversion',
    PM            => { 'Divert.pm'  => '$(INST_LIBDIR)/Divert.pm',
                       'Divert.pod' => '$(INST_LIBDIR)/Divert.pod' },
    PREREQ_PM     => {},
    AUTHOR        => 'Ralf S. Engelschall <rse@engelschall.com>'
);

