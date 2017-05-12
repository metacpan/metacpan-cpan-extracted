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
#  forms.pl
#
# -----------------------------------------------------------------------------

use strict;
use Nes;
use forms_plugin;

my $nes = Nes::Singleton->new();

my $out   = $nes->{'container'}->get_out_content();
my $forms = nes_forms_plugin->new($out);

$nes->{'container'}->set_out_content( $forms->go() );

my $nes_tags = {};
$nes_tags->{'this_plugin'} = 'forms_plugin';

foreach my $name ( keys %{$forms->{'form'}} ) {
  $forms->{'form'}{$name}->is_ok();
  my $plugin = nes_plugin->get_obj('forms_plugin');
  $plugin->add_env( 'forms_plugin', $name, 'is_ok', $forms->{'form'}{$name}->{'is_ok'} );
  if ( $forms->{'form'}{$name}->{'fatal_error'} ) {
    if ( $forms->{'form'}{$name}->{'location'} ne 'none' ) {
      if ( $forms->{'form'}{$name}->{'location'} ) {
        print "Location: $forms->{'form'}{$name}->{'location'}\n\n";
        exit;
      } else {
        print "Location: http://$ENV{'SERVER_NAME'}$ENV{'PATH_INFO'}?error_forms=$forms->{'form'}{$name}->{'fatal_error'}\n\n";
        exit;
      }
    }
  }

}

$nes->{'container'}->add_tags(%$nes_tags);

# don't forget to return a true value from the file
1;

