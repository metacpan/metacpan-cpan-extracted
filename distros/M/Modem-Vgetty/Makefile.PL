#
# $Id: Makefile.PL,v 1.1 1998/07/10 18:41:51 kas Exp $
#
# Copyright (c) 1998 Jan "Yenya" Kasprzak <kas@fi.muni.cz>. All rights
# reserved. This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use ExtUtils::MakeMaker;
WriteMakefile(
        'NAME'          => 'Modem::Vgetty',
        'VERSION_FROM'  => 'Vgetty.pm',
        'dist'          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
        );

