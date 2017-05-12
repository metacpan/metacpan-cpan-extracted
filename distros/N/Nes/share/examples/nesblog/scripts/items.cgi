#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón
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
#  items.cgi
#
# -----------------------------------------------------------------------------

use Nes;
my $nes      = Nes::Singleton->new();
my $q        = $nes->{'query'}->{'q'};
my $config   = $nes->{'CFG'};
my $action   = $q->{'action'};
my $item     = $q->{'item'};
my $nes_tags = {};

require 'lib.cgi';

@{ $nes_tags->{'articles'} } = latest(0) if $item eq 'index';
my $item_name = $q->{'item'} || last_article();
my $file_name = $config->{'miniblog_item_dir'}.'/'.$item_name.'.nhtml';

$nes_tags->{'item_name'} = $item_name;
$nes_tags->{'article'}   = $file_name;
$nes_tags->{'article'}   = 'article_index.nhtml' if $item eq 'index';

$nes->out(%$nes_tags);

1;
