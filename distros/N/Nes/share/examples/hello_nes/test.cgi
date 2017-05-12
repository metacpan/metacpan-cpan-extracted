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
#  test.cgi
#
# -----------------------------------------------------------------------------

  use strict;
  use Nes;
  
  # This test does not work if you call the cgi file
  my $nes = Nes::Singleton->new();
  
  my $nes_tags = {};
  
  $nes_tags->{'hello'} = 'Hello Nes!';

  $nes->out(%$nes_tags);


1;

