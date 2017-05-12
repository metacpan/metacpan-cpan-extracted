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
#  debug_info.pl
#
# -----------------------------------------------------------------------------

use strict;
use warnings;
use debug_info;

my $nes       = Nes::Singleton->new();
my $info      = debug_info->new($nes->{'container'});
my $container = $nes->{'container'};
my $config    = $nes->{'CFG'};

return 1 if $nes->{'top_container'}->get_nes_env('nes_remote_ip') !~ /^$config->{'debug_info_only_from_ip'}/;

$info->add();

if ( $nes->{'container'} eq $nes->{'top_container'}->{'container'} && $config->{'debug_info_show_in_out'} ) {
  
  $nes->{'container'}->set_out_content( $container->get_out_content.$info->{'out'} );
  $info->del_instance();

}

# don't forget to return a true value from the file
1;

