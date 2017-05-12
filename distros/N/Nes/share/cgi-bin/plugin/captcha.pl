#!/usr/bin/perl

# ------------------------------------------------------------------------------
#
#  NES by - Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón
#  Licensed under the GNU GPL.
#  http://nes.sourceforge.net/
# 
#  Version 0.9 pre
#
#  captcha.pl
#
# ------------------------------------------------------------------------------

use strict;
use Nes;
use captcha_plugin;

my $nes = Nes::Singleton->new();

my $out     = $nes->{'container'}->get_out_content();
my $captcha = nes_captcha_plugin->new($out);

$nes->{'container'}->set_out_content( $captcha->go() );

my $nes_tags = {};
$nes_tags->{'this_plugin'} = 'captcha_plugin';

foreach my $name ( keys %{$captcha->{'captcha'}} ) {
  $captcha->{'captcha'}{$name}->verify();
}
  
$nes->{'container'}->add_tags(%$nes_tags);

# don't forget to return a true value from the file
1;

