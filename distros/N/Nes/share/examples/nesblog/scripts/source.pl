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
#  source.pl
#
# -----------------------------------------------------------------------------


use strict;
use Nes;

my $nes      = Nes::Singleton->new();
my $cfg      = $nes->{'CFG'};
my $q        = $nes->{'query'}->{'q'};
my $config   = $nes->{'CFG'};
my $action   = $q->{'action'};
my $item     = $q->{'item'};
my $source   = $q->{'source'};

if ( $source ) {

  my $dir_plugin = $cfg->{'plugin_top_dir'};

  # Insecure dependency in require while running with -T switch at
  if ($dir_plugin =~ /^([-\@\w.\\\/]+)$/) {
      $dir_plugin = $1;                  
  }    

  push( @INC, $dir_plugin );
  do "$dir_plugin/debug_info.pl";
  
} 

1;