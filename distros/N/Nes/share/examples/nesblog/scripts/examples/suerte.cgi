#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón
#  Licensed under the GNU GPL.
#
#  Sample:
#  http://nes.sourceforge.net/
#
#  Repository:
#  http://github.com/Skriptke/nes
#
#  CPAN:
#  http://search.cpan.org/perldoc?Nes
# 
#  Version 1.00
#
#  suerte.cgi 
#
# ------------------------------------------------------------------------------

use strict;
use Nes;

my $nes = Nes::Singleton->new('./suerte.html');

my $tags = {};

$tags->{'numero_suerte'} = int (rand 10); # el número de la suerte

$nes->out(%$tags);


1;
