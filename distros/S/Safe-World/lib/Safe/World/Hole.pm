#############################################################################
## Name:        Hole.pm
## Purpose:     Safe::World::Hole - Front end for Safe::Hole
## Author:      Graciliano M. P.
## Modified by:
## Created:     23/01/2004
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Safe::World::Hole ;

use vars qw($VERSION @ISA) ;
$VERSION = '0.09';

@ISA = qw(Safe::Hole) ;

no warnings ;

###########
# REQUIRE #
###########

use Safe::Hole ;

##########
# SCOPES #
##########

my $Safe_Hole_call = \&Safe::Hole::call ;

########
# CALL #
########

sub call {
  my $this = shift ;
  if ( $Safe::Hole::VERSION == 0.09 ) { return $this->call_09_fix(@_) ;}
  else {
    &$Safe_Hole_call($this , @_) ; ## Can't use $this->SUPER::call(), since we won't find Safe::Hole::call in the scope!
  }
}

###############
# CALL_09_FIX #
###############

sub call_09_fix {
  my $this = shift ;
  my $coderef = shift ;
  my @args = @_ ;
  
  my (@r,$did_not_die) ;
  my $wantarray = wantarray ;
  
  package Safe::Hole::User ;
  
  my $inner_call = sub {
                     eval {
                       @_ = @args;
                       if ( $wantarray ) { @r = &$coderef ;}
                       else { @r = scalar &$coderef ;}
                       $did_not_die = 1 ;
                     }
                   };
  
  Safe::Hole::_hole_call_sv($this->{STASH},undef, $inner_call) ;
  
  die $@ unless $did_not_die ;
  return $wantarray ? @r : $r[0] ;
}

sub DESTROY {}

#######
# END #
#######

1;

__END__

=head1 NAME

Safe::World::Hole - Front end interface to Safe::Hole/0.08 , Safe::Hole/0.09 and Safe::Hole/0.10+

=head1 NOTE

This module is here just to handle and fix Safe::Hole/0.09.
Other versions of Safe::Hole will work fine.

B<Do not use this directly. See L<Safe::Hole>.>

=cut


