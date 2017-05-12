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
#  location.pl
#
# -----------------------------------------------------------------------------

  use Nes;
  my $nes = Nes::Singleton->new('./location.nhtml');
  my $url = $nes->{'query'}->{'q'}{'location_param_1'};
  my $sta = $nes->{'query'}->{'q'}{'location_param_2'} || "302 Found";
  
  my %tags;
  $tags{'status'} = $sta;
  $nes->out(%tags);
  
  $nes->{'container'}->{'content_obj'}->location( $url, $sta );

1;
