#
# Makefile.PL for Net::Lookup::DotTel
#
# Copyright (C) 2009 Sebastiaan Hoogeveen. All rights reserved.
#
# $Id: Makefile.PL 1305 2005-10-11 21:34:13Z sebastiaan $
#

use ExtUtils::MakeMaker;

WriteMakefile (
  NAME		=> 'Net::Lookup::DotTel',
  VERSION_FROM	=> 'lib/Net/Lookup/DotTel.pm',
  PREREQ_PM	=> {
    'Carp'	=> 0,
    'Net::DNS'  => 0.58,
  }
);
