#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Makefile.PL,v 1.1.1.1 1998/01/02 21:31:15 ken Exp $
#

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Pod::GroveBuilder',
    'VERSION_FROM' => 'GroveBuilder.pm',
    dist        => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
);
