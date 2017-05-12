#!/bin/perl

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
#  DOCUMENTATION:
#  perldoc Nes::Obj::secure_login
#  
# -----------------------------------------------------------------------------

use Nes;
use secure_login;

my $nes     = Nes::Singleton->new();
my $vars    = secure_login->new;

$nes->add(%$vars);

# don't forget to return a true value from the file
1;



 