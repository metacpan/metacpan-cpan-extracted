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
#  comments.cgi
#
# -----------------------------------------------------------------------------

use strict;
use Nes;

my $nes      = Nes::Singleton->new();
my $q        = $nes->{'query'}->{'q'};
my $config   = $nes->{'CFG'};
my $action   = $q->{'action'};
my $item     = $q->{'item'};
my $nes_tags = {};

require 'lib.cgi';

my $item_name = $q->{'item'};
my $file_name = $config->{'miniblog_item_dir'}.'/'.$item_name.'.nhtml';
   $item_name = last_article() if !-e $file_name;
   $item_name =~ s/.*\///;
   $item_name =~ s/\..?htm.?$//;   
   $file_name = $config->{'miniblog_item_dir'}.'/'.$item_name.'.nhtml';

$nes_tags->{'article'}   = $file_name;
$nes_tags->{'item_name'} = $item_name;


$nes->out(%$nes_tags);

1;
