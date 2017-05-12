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
#  Version 1.00
#
# -----------------------------------------------------------------------------

  use strict;
  use Nes;
  
  my $nes = Nes::Singleton->new('./t/test.nhtml');
  
  my $nes_tags = {};
  
  $nes_tags->{'test'} = 'Testing Nes Templates';

  $nes->out(%$nes_tags);

1;
