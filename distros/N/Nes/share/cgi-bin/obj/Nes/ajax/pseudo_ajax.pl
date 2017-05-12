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
#  pseudo_ajax.pl
#
# -----------------------------------------------------------------------------

  use strict;
  use Nes;
  
  my $nes   = Nes::Singleton->new();
  my $data  = '('.$nes->{'query'}->{'q'}{'pseudo_ajax_param_1'}.')';
  my %vars  = eval "$data";
  
  $vars{'timer'} = 0 if !$vars{'timer'};
  
  foreach my $param ( keys %{ $vars{'lparam'} } ) {
    $vars{'params'} .= $param.'='.$vars{'lparam'}{$param}.'&';
  }
  
  foreach my $param ( keys %{ $vars{'vparam'} } ) {
    $vars{'params'} .= $param.'="+'.$vars{'vparam'}{$param}.'+"&';
  }
  
  foreach my $event ( @{ $vars{'events'} } ) {
    foreach my $param ( keys %{ $event->{'lparam'} } ) {
      $event->{'params'} .= $param.'='.$event->{'lparam'}{$param}.'&';
    }
    foreach my $param ( keys %{ $event->{'vparam'} } ) {
      $event->{'params'} .= $param.'="+'.$event->{'vparam'}{$param}.'+"&';
    }
  }
  
#  $vars{'params'} =~ s/\&$//;
  
  $nes->out(%vars);

1;

