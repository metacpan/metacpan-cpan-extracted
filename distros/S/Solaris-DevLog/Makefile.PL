########################################################################
# $Id: Makefile.PL,v 1.1 2002/02/11 21:52:17 bossert Exp $
# Project:  Solaris::DevLog
# File:     Makefile.PL
# Author:   Greg Bossert <bossert@fuaim.com>, <greg@netzwert.ag>
#
# Copyright (c) 2002 Greg Bossert
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
########################################################################

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'		=> 'Solaris::DevLog',
   'VERSION_FROM'	=> 'DevLog.pm', 
   'DISTNAME'           => 'Solaris-DevLog',
   'PREREQ_PM'		=> {},
   ($] >= 5.005 ?
    (ABSTRACT_FROM => 'DevLog.pm', # retrieve abstract from module
     AUTHOR     => 'Greg Bossert <bossert@fuaim.com>') : ()),
   'LIBS'		=> ['-ldoor -lthread'],
   'XSPROTOARG'         => '-noprototypes',
   'TYPEMAPS'           => ['perlobject.map' ],
);
