#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique Castañón
#  Licensed under the GNU GPL.
#
#  CPAN:
#  http://search.cpan.org/dist/Nes/
#
#  Sample:
#  http://nes.sourceforge.net/
#
#  Repository:
#  http://github.com/Skriptke/nes
# 
#  Version 1.03
#
#  latest.cgi
#
# -----------------------------------------------------------------------------

use Nes;
my $nes = Nes::Singleton->new();
my $nes_tags = {};

require 'lib.cgi';

@{ $nes_tags->{'articles'} } = latest(10);

$nes->out(%$nes_tags);


1;
