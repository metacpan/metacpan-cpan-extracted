#############################################################################
## Name:        stdout.pm
## Purpose:     Safe::World::stdout
## Author:      Graciliano M. P.
## Modified by:
## Created:     08/09/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Safe::World::stdout ;

use strict qw(vars);

use vars qw($VERSION @ISA) ;
$VERSION = '0.02' ;

no warnings ;

##########
# SCOPES #
##########

  use vars qw($Safe_World_NOW) ;
  
  *Safe_World_NOW = \$Safe::World::NOW ;

######################
# CHECK_HEADSPLITTER #
######################

sub check_headsplitter {
  my $this = shift ;

  $this->{AUTOHEAD_DATA} .= shift ;

  my $headsplitter = $this->{HEADSPLITTER} ;

  my ($headers , $end) ;
 
  if ( ref($headsplitter) eq 'CODE' ) {
    ($headers , $end) = &$headsplitter( $Safe_World_NOW , $this->{AUTOHEAD_DATA} ) ;
  }
  elsif ( $this->{AUTOHEAD_DATA} =~ /^(.*?$headsplitter)(.*)/s ) {
    $headers = $1 ;
    $end     = $2 ;
  }
  
  delete $this->{AUTOHEAD_DATA} if $headers ne '' || $end ne '' ;
  
  return ($headers , $end) ;
}

#####################
# HEADSPLITTER_HTML #
#####################

sub headsplitter_html {
  shift ;
  my $headsplitter ;
    
  if ( $_[0] =~ /Content-Type:\s*\S+(.*?)(\015?\012\015?\012|\r?\n\r?\n)/si ) {
    if ($1 !~ /<[^>]+>/s) { $headsplitter = $2 ;}
  }
  
  ## Try to fix wrong headers:

  if ( !$headsplitter && $_[0] =~ /^(.*?)(?:\015?\012|\r?\n)([ \t]*<[^>]+>[ \t]*)(?:\015?\012|\r?\n)/s ) {
    if ($1 !~ /<[^>]+>/s) { $headsplitter = $2 ;}
  }
  
  if ( !$headsplitter && $_[0] =~ /^(.*?)(<html\s*>\s*<[^>]+>)/si ) {
    if ($1 !~ /<[^>]+>/s) { $headsplitter = $2 ;}
  }
  
  if ( !$headsplitter && $_[0] =~ /^(.*?)(<[^>]+>\s*<[^>]+>)/s ) {
    my ($s1 , $s2) = ($1,$2) ; 
    if ($s1 !~ /<[^>]+>/s && $s1 !~ /(?:^|[\r\n\015\012])[^\s:]+:[^\r\n\015\012]+$/s) {
      my ($line) = ( $s1 =~ /([^\r\n\015\012]+)$/s );
      $headsplitter = $line . $s2 ;
    }
  }
  
  if ( !$headsplitter && $_[0] =~ /^(.*?)(\015?\012\015?\012|\r?\n\r?\n)/s ) {
    if ($1 !~ /<[^>]+>/s) { $headsplitter = $2 ;}
  }
  
  my $is_all_content ;
  if ( !$headsplitter && $_[0] =~ /^(?:<[^>]+>|>)+(?:\015?\012|\r?\n)/s ) { $headsplitter = $is_all_content = 1 ;}  
  
  if ( !$headsplitter && $_[0] =~ /(?:\015?\012|\r?\n)([ \t]*(?:<[^>]+>|>)+\s)/s ) { $headsplitter = $1 ;}
  
  my ($headers , $end) ;
  
  if ( $is_all_content ) {
    $end = $_[0] ;
  }
  elsif ( $headsplitter ne '' && $_[0] =~ /^(.*?)\Q$headsplitter\E(.*)/s ) {
    $headers = $1 ;
    $end     = $2 ;
    
    if ($headsplitter !~ /^\s+$/s) { $end = "$headsplitter$end" ;}
    else { $headers .= $headsplitter ;}
  }

  return ($headers , $end) ;
}

###########
# HEADERS #
###########

sub headers {
  return '' if ref($_[0]->{HEADOUT}) ne 'SCALAR' ;
  if ($#_ >= 1) { ${$_[0]->{HEADOUT}} = $_[1] ;}
  my $headers = ${ $_[0]->{HEADOUT} } ;
  return $headers ;
}

###############
# STDOUT_DATA #
###############

sub stdout_data {
  if ( ref($_[0]->{STDOUT}) eq 'SCALAR' ) {
    if ($#_ >= 1) { ${$_[0]->{STDOUT}} = $_[1] ;}
    my $stdout = ${ $_[0]->{STDOUT} } ;
    return $stdout ;
  }
  else { return '' ;}
}

###############
# BUFFER_DATA #
###############

sub buffer_data {
  if ($#_ >= 1) { $_[0]->{BUFFER} = $_[1] ;}
  my $buf = $_[0]->{BUFFER} ;
  return $buf ;
}

#########
# BLOCK #
#########

sub block {
  my $this = shift ;
  $this->{BLOCKED} = 1 ;
}

###########
# UNBLOCK #
###########

sub unblock {
  my $this = shift ;
  $this->{BLOCKED} = undef ;
}

#########
# PRINT #
#########

sub print { &PRINT ;}

################
# PRINT_STDOUT #
################

sub print_stdout {
  #print main::STDOUT "std>> $| [[$_[1]]] [[$_[0]->{BUFFER}]]\n" ;
  my $this = shift ; return 1 if $_[0] eq '' ;
  
  return if $this->{BLOCKED} ;
  
  my $stdout = $this->{STDOUT} ;
  
  if ( $this->{AUTOHEAD} && !$_[1] ) {
    my ($headers , $end) = $this->check_headsplitter($_[0]) ;
    if ($headers ne '' || $end ne '') {
      $this->{AUTOHEAD} = undef ;
      $this->print_headout($headers,1) if $headers ne '' ;
      $this->print($end) if $end ne '' ;
      return 1 ;
    }
  }
  else {
    if ( !$_[1] ) {
      if ( !$this->{HEADER_CLOSED} && $this->{ONCLOSEHEADERS} ) {
        #print main::STDOUT "**>> $this->{HEADER_CLOSED} && $this->{ONCLOSEHEADERS}\n" ;
        $this->{HEADER_CLOSED} = 1 ;
        $this->call_oncloseheaders ;
      }
      else { $this->{HEADER_CLOSED} = 1 ;}
    }
  
    if ( ref($stdout) eq 'SCALAR' ) { $$stdout .= $_[0] ;}
    elsif ( ref($stdout) eq 'CODE' ) {
      my $sel = $Safe_World_NOW->{SELECT}{PREVSTDOUT} ? &Safe::World::SELECT( $Safe_World_NOW->{SELECT}{PREVSTDOUT} ) : undef ;
      &$stdout($Safe_World_NOW , $_[0]) ;
      &Safe::World::SELECT($sel) if $sel ;
    }
    else { print $stdout $_[0] ;}
  }

  return 1 ;
}

#################
# PRINT_HEADOUT #
#################

sub print_headout {
  my $this = shift ; return 1 if $_[0] eq '' ;
  
  my $headout = $this->{HEADOUT} ;

  return $this->print_stdout($_[0]) if !$headout ;
  
  if ( !$_[1] && $this->{AUTOHEAD} ) {
    my ($headers , $end) = $this->check_headsplitter($_[0]) ;
    if ($headers ne '' || $end ne '') {
      $this->{AUTOHEAD} = undef ;
      $this->print_headout($headers,1) if $headers ne '' ;
      $this->print($end) if $end ne '' ;
      return 1 ;
    }
    return ;
  }

  if ( ref($headout) eq 'SCALAR' ) { $$headout .= $_[0] ;}
  elsif ( ref($headout) eq 'CODE' ) {
    my $sel = $Safe_World_NOW->{SELECT}{PREVSTDOUT} ? &Safe::World::SELECT( $Safe_World_NOW->{SELECT}{PREVSTDOUT} ) : undef ;
    &$headout($Safe_World_NOW , $_[0]) ;
    &Safe::World::SELECT($sel) if $sel ;
  }
  else { print $headout $_[0] ;}

  return 1 ;
}

#################
# CLOSE_HEADERS #
#################

sub close_headers {
  my $this = shift ;
  
  ##print main::STDOUT ">> $this->{AUTOHEAD} && $this->{HEADER_CLOSED} [[$this->{AUTOHEAD_DATA}]] [[$this->{BUFFER}]]\n" ;

  ##return if !$this->{AUTOHEAD} ;
  return if (!$this->{AUTOHEAD} && $this->{HEADER_CLOSED}) || $this->{BUFFER} ne '' ;
  
  $this->{AUTOHEAD} = undef ;

  if ( $this->{AUTOHEAD_DATA} ne '' ) {
    my ($headers , $end) = $this->check_headsplitter() ;
    if ($headers ne '' || $end ne '') {
      $this->print_headout($headers,1) if $headers ne '' ;
      $this->print($end) if $end ne '' ;
    }
    else {
      $this->print( delete $this->{AUTOHEAD_DATA} ) ;
    }
  }
  
  if ( !$this->{HEADER_CLOSED} && $this->{ONCLOSEHEADERS} ) {
    $this->{HEADER_CLOSED} = 1 ;
    $this->call_oncloseheaders ;
  }

  $this->{HEADER_CLOSED} = 1 ;
  
  return 1 ;
}

#######################
# CALL_ONCLOSEHEADERS #
#######################

sub call_oncloseheaders {
  my $this = shift ;
  
  return if !$this->{ONCLOSEHEADERS} ;
  
  my $sel = $Safe_World_NOW->{SELECT}{PREVSTDOUT} ? &Safe::World::SELECT( $Safe_World_NOW->{SELECT}{PREVSTDOUT} ) : undef ;

  my $autoflush = $this->{AUTO_FLUSH} ;
  
  $this->{AUTO_FLUSH} = 1 ;

  my $oncloseheaders = $this->{ONCLOSEHEADERS} ;
  &$oncloseheaders( $Safe_World_NOW , $this->headers ) ;
  
  $this->{AUTO_FLUSH} = $autoflush ; 

  &Safe::World::SELECT($sel) if $sel ;

  return 1 ;
}

#########
# FLUSH #
#########

sub flush {
  my $this = shift ;

  if ( $this->{BUFFER} ne '' ) {
    $this->print_stdout( delete $this->{BUFFER} ) ;
    return 1 ;
  }
  
  return ;
}

#######################
# GET_AUTOFLUSH_VALUE #
#######################

sub get_autoflush_value {
  my $this = shift ;
  my $sel = select ;
  
  my $reset ;
  if ( $sel ne $this->{IO} && $sel ne 'main::STDOUT' ) { &Safe::World::SELECT($this->{IO}) ; $reset = 1 ;}
  
  my $val = $| ;
  
  if ($reset) { &Safe::World::SELECT($sel) ;}
  
  return $val ;
}

#############
# TIEHANDLE #
#############

sub TIEHANDLE {
  my $class = shift ;
  my ($root , $stdout , $flush , $headout , $autohead , $headsplitter , $oncloseheaders) = @_ ;

  my $this = {
  ROOT => $root ,
  STDOUT => $stdout ,
  HEADOUT => $headout ,
  AUTOHEAD => $autohead ,
  HEADSPLITTER => $headsplitter ,
  ONCLOSEHEADERS => $oncloseheaders ,
  AUTO_FLUSH => $flush ,
  IO => "$root\::STDOUT" ,
  } ;

  bless($this , $class) ;
  return( $this ) ;
}

sub PRINT {
  my $this = shift ;
  
  if ( $this->{REDIRECT} ) {
    ${$this->{REDIRECT}} .= join("", (@_[0..$#_])) ;
  }
  else {
    if ( !$this->{AUTO_FLUSH} && !$this->{AUTOHEAD} && !$| ) {
      #print main::STDOUT "BUF>> !$autoflus_val && !$this->{AUTO_FLUSH} && !$this->{AUTOHEAD} \n" ;
      $this->{BUFFER} .= join("", (@_[0..$#_])) ;
    }
    else {
      #print main::STDOUT "PRT>> !$autoflus_val && !$this->{AUTO_FLUSH} && !$this->{AUTOHEAD} [[$_[0]]]\n" ;
      $this->flush if $this->{BUFFER} ne '' ;
      $this->print_stdout( join("", (@_[0..$#_])) ) ;
    }
  }

  return 1 ;
}

sub PRINTF { &PRINT($_[0],sprintf($_[1],@_[2..$#_])) ;}

sub READ {}
sub READLINE {}
sub GETC {}
sub WRITE {}

sub FILENO {
  #my $this = shift ;
  #my $n = $this + 1 ;  
  #return $n ;
}

sub CLOSE {
  my $this = shift ;
  $this->{AUTO_FLUSH} = 1 ;
  $this->close_headers ;
  $this->flush ;
}

sub STORE {
  my $this = shift ;
  my $stdout = shift ;
  if ( !ref($stdout) ) {
    $stdout =~ s/^\*// ;
    $stdout = \*{$stdout} ;
  }
  $this->{STDOUT} = $stdout ;
}

sub FETCH {}

sub DESTROY {
  &CLOSE ;
}

#######
# END #
#######

1;


