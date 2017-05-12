#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Makefile.PL,v 1.2 1998/01/18 00:21:14 ken Exp $
#

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SGML::Grove',
    'VERSION_FROM' => 'Grove.pm',
    'PMLIBDIRS' => [ 'Simple' ],
    dist        => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
);
