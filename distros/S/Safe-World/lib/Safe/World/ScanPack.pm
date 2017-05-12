#############################################################################
## Name:        ScanPack.pm
## Purpose:     Safe::World::ScanPack
## Author:      Graciliano M. P.
## Modified by:
## Created:     08/09/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Safe::World::ScanPack ;
use 5.003 ;

use vars qw($VERSION *ENTRY);

$VERSION = '0.01';

no warnings ;

#######
# NEW #
#######

sub new {
  my(undef,@packages) = @_;
  no strict "refs" ;
  my $self = bless({}, __PACKAGE__) ;
  
  my @packs = $self->_scan(@packages) ;

  @packs = sort @packs ;
  $self->{PACKAGES} = \@packs ;
  
  delete $self->{SCANNEDS} ;
  
  return $self ;  
}

#########
# _SCAN #
#########

sub _scan {
  my $self = shift ;
  my(@packages) = @_;
  
  my($key,$val,$num,$pack) ;
  
  no strict "refs" ;
  
  my @scanneds ;
  
  foreach $pack (@packages) {
    my $packref = *{"$pack\::"}{HASH} ;
    $packref = "$packref" ;
    if ($self->{SCANNEDS}{$packref}) { next ;}
    $self->{SCANNEDS}{$packref}++ ;
    push(@scanneds , $packref) ;

    no strict ;
    while (($key,$val) = each(%{*{"$pack\::"}})) {
      local(*ENTRY) = $val;
      
      if (defined $val && defined *ENTRY{HASH} && $key =~ /::$/ && $key ne "main::" && $key ne "<none>::") {
        my($p) = $pack ne "main" ? "$pack\::" : "";
        ($p .= $key) =~ s/::$// ;
        my $packref = *{"$p\::"}{HASH} ;
        if ( !$self->{PACKAGES}{$p} ) {
          $self->{PACKAGES}{$p} = 1 ;
          if ( !$self->{SCANNEDS}{"$packref"} ) { push(@packages, $self->_scan($p)) ;}
          else { push(@packages, $p) ;}
        }
      }
    }
  }
  
  foreach my $scanneds_i ( @scanneds ) {
    delete $self->{SCANNEDS}{$scanneds_i} ;
  }
  
  return @packages ;
}

############
# PACKAGES #
############

sub packages { return @{ $_[0]->{PACKAGES} } ;}

#######
# END #
#######


1;


