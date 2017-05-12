#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón Barbero
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
#  register_captcha.pl
#
# -----------------------------------------------------------------------------

use strict;
use Nes;
use captcha_plugin;

my $nes = Nes::Singleton->new();

$nes->{'register'}->tag( 'captcha_plugin', 'captcha',      '' );
$nes->{'register'}->tag( 'captcha_plugin', 'captcha_code', '' );


# don't forget to return a true value from the file
1;

