# $Id: Makefile.PL,v 1.1 2000-09-23 21:23:56-04 roderick Exp $
#
# Copyright (c) 2000 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'Proc::SafePipe',
    VERSION_FROM	=> 'SafePipe.pm',
    dist		=> {
    	COMPRESS 	=> 'gzip --best',
    	DIST_CP		=> 'ln',
    	PREOP		=> '$(MAKE) ci',
    	SUFFIX		=> 'gz',
    },
    test		=> { TESTS => '*.t' },
);
