# ========================================================================
# Makefile.PL - generate Makefile for Sys::PortIO library
# Andrew Ho (andrew@zeuscat.com)
#
# Copyright (C) 2005 by Andrew Ho.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.6.0 or,
# at your option, any later version of Perl 5 you may have available.
#
# $Id: Makefile.PL,v 1.1 2005/02/26 05:19:30 andrew Exp $
# ========================================================================

require 5.006;
use warnings;
use strict;

use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
    NAME          => 'Sys::PortIO',
    VERSION_FROM  => 'PortIO.pm',
    ABSTRACT_FROM => 'PortIO.pm',
    AUTHOR        => 'Andrew Ho <andrew@zeuscat.com>',
    OPTIMIZE      => '-O2',
);

exit 0;


# ========================================================================
__END__
