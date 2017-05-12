#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: Makefile.PL,v 1.1.1.1 1998/01/17 23:47:37 ken Exp $
#

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SGML::SPGroveBuilder',
    'VERSION_FROM' => 'SPGroveBuilder.pm',
#    'LIBS'	=> ['-lsp'],
    'LIBS'	=> ['-L/home/ken/isrc/sp-1.2/lib -lsp'],
    'DEFINE'	=> '-DSP_MULTI_BYTE',
#    'INC'	=> '-I/usr/include/sp-1.2/lib'
#	      . ' -I/usr/include/sp-1.2/generic'
#	      . ' -I/usr/include/sp-1.2/include',
    'INC'	=> '-I/home/ken/isrc/sp-1.2/lib'
	      . ' -I/home/ken/isrc/sp-1.2/generic'
	      . ' -I/home/ken/isrc/sp-1.2/include',
    'OBJECT'    => "SPGroveBuilder.o SPGroveNew.o",
    dist        => {'COMPRESS'  => 'gzip', 'SUFFIX'    => '.gz'},
);
