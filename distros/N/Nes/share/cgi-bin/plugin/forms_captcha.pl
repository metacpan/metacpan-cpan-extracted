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
#  forms_captcha.pl
#
# ------------------------------------------------------------------------------

use strict;
use Nes;

my $nes = Nes::Singleton->new();

# archivo de configuración .nes.cfg
my $config = $nes->{'CFG'};

my $dir_plugin = $config->{'plugin_top_dir'};

# Insecure dependency in require while running with -T switch at
if ($dir_plugin =~ /^([-\@\w.\\\/]+)$/) {
    $dir_plugin = $1;                  
}    

do "$dir_plugin/captcha.pl";
do "$dir_plugin/forms.pl";


# don't forget to return a true value from the file
1;

