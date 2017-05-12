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
#  session.pl
#
# -----------------------------------------------------------------------------

  use Nes;
  use strict;
  
  my $nes = Nes::Singleton->new('./session.nhtml');
  my $session = $nes->{'session'};
  my $q = $nes->{'query'}->{'q'};
  
  my $action = $q->{'session_param_1'} || 'get';
  my $user   = $q->{'session_param_2'};
  my $expire = $q->{'session_param_3'} || '24h';
  my %tags;
  
  if ( $action eq 'create' ) {
    $session->create($user, $expire);
  }
  
  if ( $action eq 'del' ) {
    $session->del;
  }
  
  if ( $action eq 'get' ) {
    $tags{'user'} = $session->{'user'};
  }
  
  $nes->out(%tags);

# don't forget to return a true value from the file
1;
