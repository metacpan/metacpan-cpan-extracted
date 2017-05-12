#############################################################################
## Name:        Compartment.pm
## Purpose:     Safe::World::Compartment -> Based in the Safe module.
## Author:      Graciliano M. P.
## Modified by:
## Created:     04/12/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Safe::World::Compartment ;

use strict qw(vars) ;

no warnings ;

##########
# SCOPES #
##########

  use vars qw($Safe_World_EVALX) ;

  *Safe_World_EVALX = \$Safe::World::EVALX ;

######### *** Don't declare any lexicals above this point ***

sub reval {
  my $__EVALCODE__ = $_[1] ;
  no strict ;

  $Safe_World_EVALX += 2 ;

  return Opcode::_safe_call_sv(
    $_[0]->{Root},
    $_[0]->{Mask},
    eval("package ". $_[0]->{Root} ."; sub { \@_=(); my \$EVALX = $Safe_World_EVALX; eval \$__EVALCODE__; }")
  );
}

#############################################################################

use vars qw($VERSION @ISA) ;

$VERSION = '0.02' ;

use Opcode 1.01, qw(
  opset opset_to_ops opmask_add
  empty_opset full_opset invert_opset verify_opset
  opdesc opcodes opmask define_optag opset_to_hex
);

*ops_to_opset = \&opset ;   # Temporary alias for old Penguins
*Opcode_safe_pkg_prep = \&Opcode::_safe_pkg_prep ;

my $default_share = ['*_'] ;

my $SCALAR_R ; tie( $SCALAR_R , 'Safe::World::Compartment::SCALAR_R') ;

#############################################################################

sub new {
  my($class, $root) = @_;
  my $obj = bless({} , $class) ;

  $obj->{Root} = $root ;

  return undef if !defined($root) ;

  $obj->permit_only(':default') ;
  $obj->share_from('main', $default_share) ;
  
  {
    ## (See Safe::World::Compartment::SCALAR_R at the end of this file).
    ## Set the tied $^R to fix behavior:
    my $tmp = $_ ;
    $_ = \$SCALAR_R ;
    $obj->reval('*^R = $_') ;
    $_ = $tmp ;
    $^R = undef ; ## Ensure that is reseted.
  }
  
  Opcode_safe_pkg_prep($root) if($Opcode::VERSION > 1.04);
  
  return $obj;
}

sub deny {
  my $obj = shift;
  $obj->{Mask} |= opset(@_);
}
sub deny_only {
  my $obj = shift;
  $obj->{Mask} = opset(@_);
}

sub permit {
  my $obj = shift;
  $obj->{Mask} &= invert_opset opset(@_);
}

sub permit_only {
  my $obj = shift;
  $obj->{Mask} = invert_opset opset(@_);
}

sub share_from {
  my $obj = shift;
  my $pkg = shift;
  my $vars = shift;

  my $root = $obj->{Root} ;

  return undef if ref($vars) ne 'ARRAY' ;
  
  no strict 'refs';
  
  return undef unless keys %{"$pkg\::"} ;

  my $REF ;

  my $arg;
  foreach $arg (@$vars) {
    next unless( $arg =~ /^[\$\@%*&]?\w[\w:]*$/ || $arg =~ /^\$\W\w?$/ ) ;

    my ($var, $type);
    $type = $1 if ($var = $arg) =~ s/^(\W)// ;

    *{$root."::$var"} = (!$type) ?
      \&{$pkg."::$var"} : ($type eq '&') ?
        \&{$pkg."::$var"} : ($type eq '$') ?
          \${$pkg."::$var"} : ($type eq '@') ?
            \@{$pkg."::$var"} : ($type eq '%') ?
              \%{$pkg."::$var"} : ($type eq '*') ?
                \*{$pkg."::$var"} : undef ;
  }

  return 1 ;
}

######################################
# SAFE::WORLD::COMPARTMENT::SCALAR_R # TIE SCALAR FOR $^R
######################################

# The predefined variable $^R doesn't work like normal variables,
# that to be global lives in the main:: package. $^R doesn't exists
# at main::, soo $main::^R doesn't exists and we can't share it with
# the World compartment. $^R actually points to the last scalar returned
# by the code executed in the RE, soo $^R will point to different SCALARs
# during the RE, and if we change by hand the scalar reference of *^R it
# will be overwrited during the RE.
#
# To fix that I have used a closure in the
# FETCH and STORE methods of the TIESCALAR, and set the scalar of the
# GLOB reference inside the compartment (*^R) with the tied scalar.
# Soo, if an RE compiled inside the compartment make some reference to $^R
# it will see the external $^R through the TIED SCALAR.
# 

package Safe::World::Compartment::SCALAR_R ;

sub TIESCALAR {
  my $class = shift ;
  my $ref = shift ;
  return bless( \$ref , __PACKAGE__ ) ;
}

sub STORE {
  my $this = shift ;
  $^R = $_[0] ;
  return $^R ;
}

sub FETCH {
  my $this = shift ;
  return $^R ;
}

sub UNTIE {}
sub DESTROY {}

#######
# END #
#######

1;


