#!/usr/bin/perl

# ------------------------------------------------------------------------------
#
#  NES by - Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón
#  Licensed under the GNU GPL.
#  http://sourceforge.net/projects/nes/
# 
#  Version 0.8 beta
#
#  filter_demo.pl 
#
# ------------------------------------------------------------------------------

use strict;
use Nes;

my $nes = Nes::Singleton->new();
my $container = $nes->{'container'};
my $out = $container->get_out_content();

$out =~ s/ Nes / <b><blink>Nes<\/blink><\/b> /g;


#$container->set_out_content( "-BeGiN-".$out."-eND-" );
$container->set_out_content( $out );


# don't forget to return a true value from the file
1;

