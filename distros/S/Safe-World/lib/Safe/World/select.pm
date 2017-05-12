#############################################################################
## Name:        select.pm
## Purpose:     Safe::World::select
## Author:      Graciliano M. P.
## Modified by:
## Created:     08/09/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Safe::World::select ;

use strict qw(vars);

use vars qw($VERSION @ISA) ;
$VERSION = '0.02' ;

no warnings ;

##########
# SCOPES #
##########

  use Safe::World::Scope ;
  
  my $SCOPE_Safe_World = new Safe::World::Scope('Safe::World',undef,1) ;

  use vars qw($Safe_World_NOW $Safe_World_EVALX) ;
  
  *Safe_World_NOW = \$Safe::World::NOW ;
  *Safe_World_EVALX = \$Safe::World::EVALX ;

#######
# NEW #
#######

sub new {

##  my @call = caller(4) ; print main::STDOUT "SELECT NEW>> $_[1] [$Safe_World_NOW][$Safe_World_NOW->{SELECT}] @call\n" ;
  return undef if $_[1]->{DESTROIED} ;
  
  my $eval_err = $@ ;

  my $this = bless({} , __PACKAGE__) ;
  
  $this->{PREVWORLD} = $Safe_World_NOW ;
  $Safe_World_NOW = $this->{WORLD} = $_[1] ;
  
  $this->{WORLD}->{SELECT}  = {} if !$this->{WORLD}->{SELECT} ;
  $this->{WORLD}->{SHARING} = {} if !$this->{WORLD}->{SHARING} ;
  
  my $prevstdout = &Safe::World::SELECT( "$this->{WORLD}->{ROOT}\::STDOUT" ) ;
  $this->{WORLD}->{SELECT}{PREVSTDOUT} = $this->{PREVSTDOUT} = [$prevstdout , \*{$prevstdout}] ;
  
  $this->{WORLD}->{SELECT}{PREVSTDERR} = $this->{PREVSTDERR} = *main::STDERR{IO} ;
  $this->{WORLD}->{SELECT}{PREVSUBWARN} = $this->{PREVSUBWARN} = $SIG{__WARN__} ;
  $this->{WORLD}->{SELECT}{PREVSUBDIE} = $this->{PREVSUBDIE} = $SIG{__DIE__} ;

  open (STDERR,">&$this->{WORLD}->{ROOT}::STDERR") ;
  $SIG{__WARN__} = \&print_stderr ;
  $SIG{__DIE__} = \&handle_die ;
  
  foreach my $var ( keys %{ $this->{WORLD}->{SHARING} } ) {
    $this->{WORLD}->{SHARING}{$var}{OUT} = &out_get_ref_copy($var) ;
    if ( $this->{WORLD}->{SHARING}{$var}{IN} ) {
      &out_set($var , $this->{WORLD}->{SHARING}{$var}{IN}) ;
      $this->{WORLD}->{SHARING}{$var}{IN} = undef ;
    }
  }
  
  if ( $this->{WORLD}->{TIESTDOUT} && $this->{WORLD}->{TIESTDOUT}->{AUTO_FLUSH} ) { $| = 1 ;}

  $this->{WORLD}->set('$SAFEWORLD', $this->{WORLD} , 1 ) if !$this->{WORLD}->{NO_SET_SAFEWORLD} ;

  if ( $this->{WORLD}->{ONSELECT} ) {
    my $sub = $this->{WORLD}->{ONSELECT} ;
    &$sub($this->{WORLD}) ;
  }
  
  $SCOPE_Safe_World->call('sync_evalx') ; ## Safe::World::sync_evalx() ;
  
  $@ = $eval_err ;

  return $this ;
}

###########
# DESTROY #
###########

sub DESTROY {
  my $this = shift ;
  
  ##print main::STDOUT "SELECT DESTROY>> $this\n" ;  
  
  my $eval_err = $@ ;
  
  %{$this->{WORLD}->{SELECT}} = () ;
  
  $this->{WORLD}->set('$SAFEWORLD', \undef) if !$this->{WORLD}->{NO_SET_SAFEWORLD} ;
  
  if ( $this->{WORLD}->{ONUNSELECT} ) {
    my $sub = $this->{WORLD}->{ONUNSELECT} ;
    &$sub($this->{WORLD}) ;
  }

  *main::STDERR = $this->{PREVSTDERR} ;
  $SIG{__WARN__} = $this->{PREVSUBWARN} ;
  $SIG{__DIE__} = $this->{PREVSUBDIE} ;

  foreach my $var ( keys %{ $this->{WORLD}->{SHARING} } ) {
    $this->{WORLD}->{SHARING}{$var}{IN} = &out_get_ref_copy($var) ;
    if ( $this->{WORLD}->{SHARING}{$var}{OUT} ) {
      &out_set($var , $this->{WORLD}->{SHARING}{$var}{OUT}) ;
      $this->{WORLD}->{SHARING}{$var}{OUT} = undef ;
    }
  }
  
  &Safe::World::SELECT($this->{PREVSTDOUT}) ;

  $Safe_World_NOW = (ref($this->{PREVWORLD}) eq 'Safe::World') ? $this->{PREVWORLD} : undef ;
  
  $SCOPE_Safe_World->call('sync_evalx') ; ## Safe::World::sync_evalx() ;
  
  $@ = $eval_err ;
  
  return ;
}

####################
# OUT_GET_REF_COPY #
####################

sub out_get_ref_copy {
  my ( $varfull ) = @_ ;
  
  my ($var_tp,$var) = ( $varfull =~ /([\$\@\%\*])(\S+)/ ) ;
  $var =~ s/^{'(\S+)'}$/$1/ ;
  $var =~ s/^main::// ;

  if ($var_tp eq '$') { return ${'main::'.$var} ;}
  elsif ($var_tp eq '@') { return [@{'main::'.$var}] ;}
  elsif ($var_tp eq '%') { return {%{'main::'.$var}} ;}
  elsif ($var_tp eq '*') { return \*{'main::'.$var} ;}
  else                   { ++$Safe_World_EVALX ; return eval("package main ; \\$varfull") ;}
}

###########
# OUT_SET #
###########

sub out_set {
  my ( $var , $val ) = @_ ;

  my ($var_tp,$name) = ( $var =~ /([\$\@\%\*])(\S+)/ );
  $name =~ s/^{'(\S+)'}$/$1/ ;
  $name =~ s/^main::// ;
  
  if    ($var_tp eq '$') { ${'main::'.$name} = $val ;}
  elsif ($var_tp eq '@') { @{'main::'.$name} = @{$val} ;}
  elsif ($var_tp eq '%') { %{'main::'.$name} = %{$val} ;}
  elsif ($var_tp eq '*') { *{'main::'.$name} = $val ;}
  else  { ++$Safe_World_EVALX ; eval("$var = \$val ;") ;}  
}

################
# PRINT_STDERR #
################

sub print_stderr {
  $Safe_World_NOW->print_stderr(@_) ;  return ;
}

##############
# HANDLE_DIE #
##############

sub handle_die {
  my $core_exit = ($_[0] =~ /#CORE::GLOBAL::exit#/) ? 1 : undef ;

  $Safe_World_NOW->{EXIT} = 1 if $core_exit ;
  $Safe_World_NOW->print_stderr(@_) if !$core_exit ;
  $Safe_World_NOW->close if $core_exit ;
  
  $@ = undef if $core_exit ;
  
  return ;
}

#######
# END #
#######

1;

