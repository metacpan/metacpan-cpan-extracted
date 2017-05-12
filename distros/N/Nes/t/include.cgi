#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  NES by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón
#  Licensed under the GNU GPL.
#
#  Sample:
#  http://nes.sourceforge.net/
#
#  Repository:
#  http://github.com/Skriptke/nes
# 
#  Version 1.00_01
#
# -----------------------------------------------------------------------------

  use strict;
  use Nes;
  
  my $nes = Nes::Singleton->new('./t/include.nhtml');
  
  $nes->out();


1;

