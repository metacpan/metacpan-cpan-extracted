#############################################################################
## Name:        World.pm
## Purpose:     Safe::World
## Author:      Graciliano M. P.
## Modified by:
## Created:     08/09/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Safe::World ;

use strict qw(vars);

use vars qw($VERSION @ISA) ;
$VERSION = '0.14' ;

require overload ;

no warnings ;

########
# VARS #
########

  use vars qw($NOW $EVALX) ;

  my ($COMPARTMENT_X , $SAFE_WORLD_SELECTED_STATIC , %WORLDS_LINKS , $IGNORE_EXIT , $SELECT_STDOUT_FIX , $UNIVERSAL_ISA , $TRACK_GLOB_X) ;
  
  my $COMPARTMENT_NAME = 'SAFEWORLD' ;
  my $COMPARTMENT_NAME_CACHE = 'SAFEWORLD_CACHE_' ;
  
  my $TRACK_GLOBS_BASE = 'Safe::World::GLOBS::' ;
  
  my @DENY_OPS = qw(chroot syscall exit dump fork lock threadsv) ;
  
  my @TRACK_VARS_DEF = qw(*_ @INC %INC %ENV) ;

  my $MAIN_STASH = *{'main::'}{HASH} ;
  
  my $BLESS_TABLE = { POOL => Hash::NoRef->new() } ;
  my $SAFEWORLDS_TABLE = { POOL => Hash::NoRef->new() } ;

  
  ########
  # KEYS #
  ########
  ## STDOUT          ## stdout ref (GLOB|SCALAR|CODE)
  ## STDIN           ## stdin ref (GLOB)
  ## STDERR          ## stderr ref (GLOB|SCALAR|CODE)
  ## HEADOUT         ## the output of the headers (GLOB|SCALAR|CODE)
  ## TIESTDOUT       ## The tiestdout object
  ## TIESTDERR       ## The tiestderr object
  
  ##                 ## Auto flush (BOOL)
  ## AUTOHEAD        ## If STDOUT start printing the headers, until HEADSPLITTER (like CGI). Def: 1 if HEADOUT
  ## HEADSPLITTER    ## The splitter (REGEXP|CODE) between headers and output. Def: \r\n\r\n (like CGI)
  ## ONCLOSEHEADERS  ## Function to call on close headers block.
  
  ## ENV             ## Internal %ENV
  
  ## ROOT            ## root name
  ## SAFE            ## the Safe object
  ## SHAREDPACK      ## what package to share in this WORLD when it's linked with other>> \@
      
  ## INSIDE          ## bool >> if is running code inside the compartment

  ## LINKED_PACKS{}  ## shared packages
  ## SHARING{}       ## shared vars
  ## WORLD_SHARED    ## if this world is shared and the name of the holder.
  ## SELECT{}        ## Safe::World::select keys.

  ## NO_SET_SAFEWORLD  ## Do not set the variable $SAFEWORLD inside the compartment.
  ## NO_CLEAN        ## If will not clean the pack.

  ## DESTROIED       ## if DESTROY() was alredy called.
  ## CLEANNED        ## if the pack was cleanned.
  ## EXIT            ## exit or die has been called. No more evals!
  
  ##########
  # EVENTS #
  ##########
  ## on_closeheaders  ## When the headers are closeds.
  ## on_exit          ## When exit() is called.
  ## on_select        ## When the WORLD is selected to evaluate codes inside it.
  ## on_unselect      ## When the WORLD is unselected, just after evaluate the codes.
  
  ###############
  # COMPARTMENT #
  ###############
  ## SAFEWORLDx::WORLDSHARE::  ## used to link and unlink a WORLD with other WORLD.

########
# EXIT #
########

sub EXIT {
  return if $IGNORE_EXIT ;
  
  if ( $NOW && ref($NOW) eq 'Safe::World' ) {
    my $exit ;
    if ( $NOW->{ONEXIT} && !$NOW->{EXIT} ) {
      my $sub = $NOW->{ONEXIT} ;
      $exit = &$sub($NOW , @_) ;
    }
    die('#CORE::GLOBAL::exit#') unless $exit eq '0' ;
  }
  else { CORE::exit(@_) ;}
}

##########
# SELECT #
##########

sub SELECT {
  if ( @_ > 1 ) {
    return CORE::select($_[0],$_[1],$_[2],$_[3]) ;
  }

  my ( $io ) = @_ ;
  
  ##open (LOG,">>F:/projects/HPL7/DEV/apps/safeworld-$$.tmp") ;

  my $outside = ($MAIN_STASH == *{"main::"}{HASH}) ? 1 : undef ;

  my $root = ref $NOW ? $NOW->{ROOT} : undef ;

  my ($prev_sel , $io_ref) ;
  if ( ref($io) eq 'ARRAY') { ($io , $io_ref) = @{$io} ;}
  
  if ( ref($io) ) { ; }
  elsif ( $io =~ /^(?:main::)*(?:STDOUT|stdout)$/s ) {
    $io = $outside ? 'main::STDOUT' : "$root\::STDOUT" ;
    $prev_sel = $io ;
  }
  elsif ( $io =~ /^(?:(?:main|(SAFEWORLD(?:_CACHE_)?\d+))::)+(?:STDOUT|stdout)$/s ) {
    my $pack = $1 || 'main' ;
    $io = "$pack\::STDOUT" ;
    $prev_sel = $io ;
  }
  elsif ( $io ne '' && $io !~ /::/ && $io !~ /^(?:STDOUT|STDERR|STDIN)$/ ) {
    my $caller = caller ;
    $io = "$caller\::$io" ;
  }
  
  my $sel = $io ne '' ? CORE::select($io_ref||$io) : CORE::select() ;
  ##my $sel0 = $sel ;
  
  if ( $sel =~ /^(?:(?:main|(SAFEWORLD(?:_CACHE_)?\d+))::)*(?:STDOUT|stdout)$/s ) {
    my $pack = $1 || 'main' ;
    $sel = "$pack\::STDOUT" ;
    if ( $sel eq 'main::STDOUT' && $SELECT_STDOUT_FIX ) { $sel = $SELECT_STDOUT_FIX ;}
  }

  $SELECT_STDOUT_FIX = $prev_sel if $io ne '' ;
  
  ##my @call = caller ;
  ##print LOG "$outside>> $sel # $io { $sel0 # $_[0] } <<@call>>\n" ;
  ##close(LOG) ;
  
  return $sel ;
}

#################
# UNIVERSAL_ISA #
#################

sub UNIVERSAL_ISA {
  my $ref = shift ;
  my $class = shift ;
  
  my $outside = ($MAIN_STASH == *{"main::"}{HASH}) ? 1 : undef ;
  my $root = ref $NOW ? $NOW->{ROOT} : undef ;
  
  if ( $class eq 'UNIVERSAL' && is_SvBlessed($ref) ) { return 1 ;}
  
  if ( !$outside ) {
    my $class1 = "$root\::$class" ;
    my ($class2) = ( ref($ref) =~ /^(?:(?:main|(SAFEWORLD(?:_CACHE_)?\d+))::)*.*$/s );
    $class2 = "$class2\::$class" if $class2 ;
    return &$UNIVERSAL_ISA($ref , $class) || &$UNIVERSAL_ISA($ref , $class1) || ( $class2 ? &$UNIVERSAL_ISA($ref , $class2) : undef ) ;
  }
  else {
    return &$UNIVERSAL_ISA($ref , $class) ;
  }
}

##########
# CALLER #
##########

sub CALLER {
  my @ret ;
  if ( @_ ) { @ret = CORE::caller($_[0]+1) ;}
  else { @ret = (CORE::caller(1))[0..2] ;}
  
  my $outside = ($MAIN_STASH == *{"main::"}{HASH}) ? 1 : undef ;
  
  if ( !$outside ) {
    if ( $ret[0] =~ /^(?:main|(?:SAFEWORLD(?:_CACHE_)?\d+))(::.*|)$/ ) {
      $ret[0] = "main$1" ;
    }
  }
  
  return @ret if wantarray ;
  return $ret[0] ;
}

#########
# BLESS #
#########

sub BLESS {
  my $ref ;
  if ( $#_ == 0 ) {
    my $class = CORE::caller ;
    $ref = bless($_[0],$class) ;
  }
  else { $ref = bless($_[0] , $_[1]) ;}

  my $outside = ($MAIN_STASH == *{"main::"}{HASH}) ? 1 : undef ;

  if (
       !$outside 
       && ref($ref) !~ /^(?:(?:main|(?:SAFEWORLD(?:_CACHE_)?\d+))::)?Safe::World(?:::(?:Compartment|select).*)?$/
       && (
            $] >= 5.007
            || (
                 #!ref($ref)->can('()')
                 #&&
                 ref($ref) !~ /^(?:(?:main|(?:SAFEWORLD(?:_CACHE_)?\d+))::)?(?:Object::MultiType.*|XML::Smart)$/
               )
           )
     ) {
    my $id = ++$BLESS_TABLE->{id} ;
    my ($base) = ( *{"main::"}{HASH}{'main::'} =~ /^\W*(?:main::)*(\w+)/ ) ;
    $BLESS_TABLE->{POOL}{$id} = $ref ;
    $BLESS_TABLE->{$base}{$id} = undef ;
    ##print STDOUT "BLESS>> [". ref($ref) ."] # $id\n" ;
  }

  return $ref ;
}

sub _rebless {
  my ( $pack , $new_pack ) = @_ ;
  #print STDOUT "REBLESS>>@_\n" ;

  foreach my $ids_i ( keys %{$BLESS_TABLE->{$pack}} ) {
    my $obj = $BLESS_TABLE->{POOL}{$ids_i} ;
    my $ref = ref($obj) ;
    ##print STDOUT "REBLESS>> $obj # $ref # $ids_i <$pack , $new_pack >\n" ;
    if ( $ref &&
         $ref ne 'SCALAR' &&
         $ref ne 'ARRAY' &&
         $ref ne 'HASH' &&
         $ref ne 'CODE' &&
         $ref ne 'GLOB' &&
         $ref ne 'FORMAT' &&
         $ref ne 'REF' &&
         $ref ne 'UNKNOW' &&
         $ref !~ /^(?:main|(?:SAFEWORLD(?:_CACHE_)?\d+)::)?Safe::World(?:[\w:]*)$/
    ) {
      if ( $ref =~ /^(?:main|(?:SAFEWORLD(?:_CACHE_)?\d+))(?:::(.*)|)$/ ) { $ref = $1 || 'main' ;}
      CORE::bless($obj , "$new_pack\::$ref") ;
    }
    else {
      delete $BLESS_TABLE->{POOL}{$ids_i} ;
      delete $BLESS_TABLE->{$pack}{$ids_i} ;
    }
  }

  return ;
}

#########
# BEGIN #
#########

use Opcode ; ## Need to load Opcode before redefine caller!

sub BEGIN {
  *CORE::GLOBAL::exit = \&EXIT ;
  *CORE::GLOBAL::select = \&SELECT ; ## Fix different behavior of STDOUT select() inside Safe compartments on Perl-5.6x and Perl-5.8x.
  *CORE::GLOBAL::caller = \&CALLER ;
  *CORE::GLOBAL::bless = \&BLESS ;
  $UNIVERSAL_ISA = \&UNIVERSAL::isa ;
  *UNIVERSAL::isa = \&UNIVERSAL_ISA ;
}

############
# REQUIRES #
############

use Hash::NoRef ;
use Safe::World::Compartment ;
use Safe::World::ScanPack ;

require Safe::World::select ; ## To be loaded after declare Safe::World scope.
use Safe::World::stdout ;
use Safe::World::stdoutsimple ;
use Safe::World::stderr ;

##########
# SCOPES #
##########

  use Safe::World::Scope ;

  my $SCOPE_Safe_World_stdout = new Safe::World::Scope('Safe::World::stdout',undef,1) ;
  my $SCOPE_Safe_World_Compartment = new Safe::World::Scope('Safe::World::Compartment',undef,1) ;
  my $SCOPE_Safe_World_select = new Safe::World::Scope('Safe::World::select',undef,1) ;
  my $SCOPE_Safe_World_ScanPack = new Safe::World::Scope('Safe::World::ScanPack',undef,1) ;
  
  my $Safe_World_stdout_headsplitter_html = \&Safe::World::stdout::headsplitter_html ;
  
  *is_SvBlessed = \&Hash::NoRef::is_SvBlessed ;

#########
# ALIAS #
#########

sub root { $_[0]->{ROOT} ;}
sub safe { $_[0]->{SAFE} ;}

sub tiestdout { $_[0]->{TIESTDOUT} ;}
sub tiestderr { $_[0]->{TIESTDERR} ;}

sub headers {
  my $this = shift ;
  return if $this->{NO_IO} ;
  return $this->{TIESTDOUT}->headers(@_) ;
}

sub stdout_data {
  my $this = shift ;
  return if $this->{NO_IO} ;
  return $this->{TIESTDOUT}->stdout_data(@_) ;
}

sub stdout_buffer_data {
  my $this = shift ;
  return if $this->{NO_IO} ;  
  return $this->{TIESTDOUT}->buffer_data(@_) ;
}

#######
# NEW # root , stdout , stdin , stderr , env , headout , headsplitter , autohead , &on_closeheaders , &on_exit , &on_select , &on_unselect , sharepack , flush , no_clean , no_set_safeworld
#######

sub new {
  my $class = shift ;
  my $this = bless({} , $class) ;
  my ( %args ) = @_ ;
  
  $this->{NO_IO} = 1 if $args{no_io} ;
  
  if ( !$this->{NO_IO} ) {
    $this->{STDOUT}  = $args{stdout} || \*main::STDOUT ;
    $this->{STDIN}   = $args{stdin} || \*main::STDIN ;
    $this->{STDERR}  = $args{stderr} || \*main::STDERR ;
    $this->{HEADOUT} = $args{headout} ;
    
    if ( !ref($this->{STDOUT}) )                      { $this->{STDOUT}  = \*{$this->{STDOUT}} ;}
    if ( !ref($this->{STDIN}) )                       { $this->{STDIN}   = \*{$this->{STDIN}} ;}
    if ( !ref($this->{STDERR}) )                      { $this->{STDERR}  = \*{$this->{STDERR}} ;}
    if ( $this->{HEADOUT} && !ref($this->{HEADOUT}) ) { $this->{HEADOUT} = \*{$this->{HEADOUT}} ;}
    
    if ( ref($this->{HEADOUT}) !~ /^(?:GLOB|SCALAR|CODE)$/ ) { $this->{HEADOUT} = undef ;}
    
    ${$this->{STDOUT}}  .= '' if ref($this->{STDOUT}) eq 'SCALAR' ;
    ${$this->{STDERR}}  .= '' if ref($this->{STDERR}) eq 'SCALAR' ;
    ${$this->{HEADOUT}} .= '' if ref($this->{HEADOUT}) eq 'SCALAR' ;
    
    ####
  
    $this->{FLUSH} = $args{flush} ;
    
    $this->{AUTOHEAD} = $args{autohead} if exists $args{autohead} ;
    $this->{AUTOHEAD} = 1 if ($this->{HEADOUT} && !exists $args{autohead}) ;
    
    $this->{HEADSPLITTER} = $args{headsplitter} || $args{headspliter} || qr/(?:\r\n\r\n|\012\015\012\015|\n\n|\015\015|\r\r|\012\012)/s if $this->{AUTOHEAD} ;
    if ( $this->{HEADSPLITTER} eq 'HTML' ) {
      $this->{HEADSPLITTER} = $Safe_World_stdout_headsplitter_html ; ##\&Safe::World::stdout::headsplitter_html ;
    }
    
    ####
    
    
    $this->{ONCLOSEHEADERS} = $args{on_closeheaders} if (ref($args{on_closeheaders}) eq 'CODE') ;
    $this->{ONEXIT} = $args{on_exit} if (ref($args{on_exit}) eq 'CODE') ;
  
    $this->{ONSELECT} = $args{on_select} if (ref($args{on_select}) eq 'CODE') ;
    $this->{ONUNSELECT} = $args{on_unselect} if (ref($args{on_unselect}) eq 'CODE') ;
  }
  
  ####
                  
  $this->{SHAREDPACK} = $args{sharepack} ;
  if ( $this->{SHAREDPACK} && ref($this->{SHAREDPACK}) ne 'ARRAY' ) { $this->{SHAREDPACK} = [$this->{SHAREDPACK}] ;}
  
  if ( $this->{SHAREDPACK} ) {
    foreach my $packs_i ( @{ $this->{SHAREDPACK} } ) {
      $packs_i =~ s/[^\w:\.]//gs ;
      $packs_i =~ s/[:\.]+/::/ ;
      $packs_i =~ s/^(?:main)?::// ;
      $packs_i =~ s/::$// ;
      my $pm = $packs_i ;
      $pm =~ s/::/\//g ;
      $pm .= '.pm' ;
      $this->{SHAREDPACK_PM}{$packs_i} = $pm ;
    }
  }
  
  ####
  
  $this->{ENV} = $args{env} || $args{ENV} ;
  if ( ref($this->{ENV}) ne 'HASH') { $this->{ENV} = undef ;}

  my $packname = $args{root} ;
  
  if ( !$packname ) {
    $packname = $args{is_cache} ? $COMPARTMENT_NAME_CACHE : $COMPARTMENT_NAME ;
    $packname .= ++$COMPARTMENT_X ;
    $this->{IS_CACHE} = 1 if $args{is_cache} ;
  }

  $this->{ROOT} = $packname ;
 
  $this->{NO_SET_SAFEWORLD} = 1 if $args{no_set_safeworld} ;
  $this->{NO_CLEAN} = 1 if $args{no_clean} ;
  
  $this->{SAFE} = $SCOPE_Safe_World_Compartment->NEW($packname) ; # Safe::World::Compartment->new($packname) ;
  $this->{SAFE}->deny_only(@DENY_OPS) ;

  *{"$packname\::$packname\::"} = *{"$packname\::"} ;
  *{"$packname\::main::"} = *{"$packname\::"} ;
  
  if ( $this->{SHAREDPACK} ) {
    $this->{SAFE}->reval(q`package WORLDSHARE ;`);
  }
  
  ###
  
  if ( !$this->{NO_IO} ) {
    if ( $this->{FLUSH} && !$this->{HEADOUT} && !$this->{AUTOHEAD} ) {
      $this->{TIESTDOUT} = tie(*{"$packname\::STDOUT"} => 'Safe::World::stdoutsimple' , $this->{ROOT} , $this->{STDOUT} ) ;
    }
    else {
      $this->{TIESTDOUT} = tie(*{"$packname\::STDOUT"} => 'Safe::World::stdout' , $this->{ROOT} , $this->{STDOUT} , $this->{FLUSH} , $this->{HEADOUT} , $this->{AUTOHEAD} , $this->{HEADSPLITTER} , $this->{ONCLOSEHEADERS} ) ;
    }
  
    $this->{TIESTDERR} = tie(*{"$packname\::STDERR"} => 'Safe::World::stderr' , $this->{ROOT} , $this->{STDERR} ) ;
    
    *{"$packname\::STDIN"}  = $this->{STDIN}  if $this->{STDIN} ;
  }
  
  ###
    
  $this->link_pack('UNIVERSAL') ;
  $this->link_pack('attributes') ;
  $this->link_pack('DynaLoader') ;  
#  $this->link_pack('IO') ;
  
#  $this->link_pack('Exporter') ;
#  $this->link_pack('warnings') ;
  
#  $this->link_pack('AutoLoader') ;
#  $this->link_pack('Carp') ;
#  $this->link_pack('Config') ;
#  $this->link_pack('Errno') ;
#  $this->link_pack('overload') ;
#  $this->link_pack('re') ;  
#  $this->link_pack('subs') ;  
#  $this->link_pack('vars') ;    

  $this->link_pack('CORE') ;  
  
  $this->link_pack('<none>') ;  
  
  $this->link_pack('Apache') if defined *{"Apache::"} ;
  $this->link_pack('Win32') if defined *{"Win32::"} ;

  $this->share_vars( 'main' , [
  '@INC' , '%INC' ,
  '$@','$|','$_', '$!',
  #'$-', , '$/' ,'$!','$.' ,
  ]) ;
  
  $this->select_static ;

  $this->set_vars(
  '%SIG' => \%SIG ,
  '$/' => $/ ,
  '$"' => $" ,
  '$;' => $; ,
  '$$' => $$ ,
  '$^W' => 0 ,
  ( $this->{ENV} ? ('%ENV' => $this->{ENV}) : () ) ,
  ) ;

  $this->set('%INC',{}) ;
  
  $this->eval("no strict ;") if !$args{no_strict} ; ## just to load strict inside the compartment.

  #$this->track_vars(':defaults') if !$this->{TRACK_VARS_DEF} && $this->{SHAREDPACK} ;
  
  $this->track_vars(qw(>STDOUT >STDERR <STDIN)) if $this->{NO_IO} ;
  
  $this->unselect_static ;
  
  $SAFEWORLDS_TABLE->{POOL}{ $this->{ROOT} } = $this ;

  return $this ;
}

###########
# OPCODES #
###########

sub op_deny {
  my $this = shift ;
  $this->{SAFE}->deny(@_);
}

sub op_deny_only {
  my $this = shift ;
  $this->{SAFE}->deny_only(@_);
}

sub op_permit {
  my $this = shift ;
  $this->{SAFE}->permit(@_);
}

sub op_permit_only {
  my $this = shift ;
  $this->{SAFE}->permit_only(@_);
}

##############
# SYNC_EVALX #
##############

sub sync_evalx {
  my $tmp = $@ ;
  eval("=1") ;
  $@ = $tmp ;
  my ($evalx) = ( $@ =~ /\(eval (\d+)/s );
  $EVALX = $evalx ;
}

#########
# RESET #
#########

sub reset {
  my $this = shift ;
  my ( %args ) = @_ ;
  
  my $packname = $this->{ROOT} ;
  
  $this->reset_internals ;
  
  if ( !$this->{NO_IO} ) {
    $this->{STDOUT}  = $args{stdout} if $args{stdout} ;
    $this->{STDIN}   = $args{stdin} if $args{stdin} ;
    $this->{STDERR}  = $args{stderr} if $args{stderr} ;
    $this->{HEADOUT} = $args{headout} if $args{headout} ;
    
    if ( $this->{STDOUT}  && !ref($this->{STDOUT}) )   { $this->{STDOUT}  = \*{$this->{STDOUT}} ;}
    if ( $this->{STDIN}   && !ref($this->{STDIN}) )    { $this->{STDIN}   = \*{$this->{STDIN}} ;}
    if ( $this->{STDERR}  && !ref($this->{STDERR}) )   { $this->{STDERR}  = \*{$this->{STDERR}} ;}
    if ( $this->{HEADOUT} && !ref($this->{HEADOUT}) )  { $this->{HEADOUT} = \*{$this->{HEADOUT}} ;}
    
    if ( ref($this->{HEADOUT}) !~ /^(?:GLOB|SCALAR|CODE)$/ ) { $this->{HEADOUT} = undef ;}
    
    ${$this->{STDOUT}}  .= '' if ref($this->{STDOUT}) eq 'SCALAR' ;
    ${$this->{STDERR}}  .= '' if ref($this->{STDERR}) eq 'SCALAR' ;
    ${$this->{HEADOUT}} .= '' if ref($this->{HEADOUT}) eq 'SCALAR' ;
  }
  
  my $env = $args{env} || $args{ENV} ;
  
  if ( $env ) {
    $this->{ENV} = $env ;
    if ( ref($this->{ENV}) ne 'HASH') { $this->{ENV} = undef ;}  
  }
  
  my $sel = $this->select_static ;
  
  $this->set_vars(
  '%SIG' => \%SIG ,
  '$/' => $/ ,
  '$"' => $" ,
  '$;' => $; ,
  '$$' => $$ ,
  '$^W' => 0 ,
  ( $env ? ('%ENV' => $this->{ENV}) : () ) ,
  ) ;
  
  if ( !$this->{NO_IO} ) {
    untie(*{"$packname\::STDOUT"}) ;
    untie(*{"$packname\::STDERR"}) ;
    
    if ( $this->{FLUSH} && !$this->{HEADOUT} && !$this->{AUTOHEAD} ) {
      $this->{TIESTDOUT} = tie(*{"$packname\::STDOUT"} => 'Safe::World::stdoutsimple' , $this->{ROOT} , $this->{STDOUT} ) ;
    }
    else {
      $this->{TIESTDOUT} = tie(*{"$packname\::STDOUT"} => 'Safe::World::stdout' , $this->{ROOT} , $this->{STDOUT} , $this->{FLUSH} , $this->{HEADOUT} , $this->{AUTOHEAD} , $this->{HEADSPLITTER} , $this->{ONCLOSEHEADERS} ) ;
    }
  
    $this->{TIESTDERR} = tie(*{"$packname\::STDERR"} => 'Safe::World::stderr' , $this->{ROOT} , $this->{STDERR} ) ;
    
    *{"$packname\::STDIN"}  = $this->{STDIN}  if $this->{STDIN} ;
  }
  
  sync_evalx() ;
  
  $this->unselect_static if $sel ;
  
  return 1 ;
}

###################
# RESET_INTERNALS #
###################

sub reset_internals {
  my $this = shift ;
  
  $this->{EXIT}      = undef ;
  $this->{DESTROIED} = undef ;
  $this->{CLEANNED}  = undef ;
}

################
# RESET_OUTPUT #
################

sub reset_output {
  my $this = shift ;
  return if $this->{NO_IO} ;
  
  my ( %args ) = @_ ;
  
  my $packname = $this->{ROOT} ;
  
  if ( $args{stdout} ) {
    $this->{STDOUT} = $args{stdout} ;

    if ( $this->{STDOUT} && !ref($this->{STDOUT}) ) { $this->{STDOUT} = \*{$this->{STDOUT}} ;}
    #if ( ref($this->{STDOUT}) !~ /^(?:GLOB|SCALAR|CODE)$/ ) { $this->{STDOUT}  = undef ;}
    ${$this->{STDOUT}} .= '' if ref($this->{STDOUT}) eq 'SCALAR' ;
    
    $this->{TIESTDOUT}->{STDOUT} = $this->{STDOUT} if $this->{STDOUT} ;
  }
  
  if ( $args{stderr} ) {
    $this->{STDERR} = $args{stderr} ;

    if ( $this->{STDERR} && !ref($this->{STDERR}) ) { $this->{STDERR} = \*{$this->{STDERR}} ;}
    #if ( ref($this->{STDERR}) !~ /^(?:GLOB|SCALAR|CODE)$/ ) { $this->{STDERR}  = undef ;}
    ${$this->{STDERR}} .= '' if ref($this->{STDERR}) eq 'SCALAR' ;
    
    $this->{TIESTDERR}->{STDERR} = $this->{STDERR} if $this->{STDERR} ;
  }
  
  if ( $args{headout} ) {
    $this->{HEADOUT} = $args{headout} ;

    if ( $this->{HEADOUT} && !ref($this->{HEADOUT}) ) { $this->{HEADOUT} = \*{$this->{HEADOUT}} ;}
    if ( ref($this->{HEADOUT}) !~ /^(?:GLOB|SCALAR|CODE)$/ ) { $this->{HEADOUT} = undef ;}
    ${$this->{HEADOUT}} .= '' if ref($this->{HEADOUT}) eq 'SCALAR' ;
    
    $this->{TIESTDOUT}->{HEADOUT} = $this->{HEADOUT} if $this->{HEADOUT} ;
  }
  
  if ( $args{stdin} ) {
    $this->{STDIN} = $args{stdin} ;

    if ( $this->{STDIN} && !ref($this->{STDIN}) ) { $this->{STDIN} = \*{$this->{STDIN}} ;}
    #if ( ref($this->{STDIN}) !~ /^(?:GLOB)$/ ) { $this->{STDIN} = undef ;}

    *{"$packname\::STDIN"}  = $this->{STDIN} if $this->{STDIN} ;
  }
  
  return 1 ;
}

#################
# SELECT_STATIC #
#################

sub select_static {
  if ( !$SAFE_WORLD_SELECTED_STATIC && $NOW != $_[0] ) {
    $SAFE_WORLD_SELECTED_STATIC = $SCOPE_Safe_World_select->NEW($_[0]) ; ## Safe::World::select->new($_[0]) ;
    return 1 ;
  }
  return ;
}

###################
# UNSELECT_STATIC #
###################

sub unselect_static {
  if ( $SAFE_WORLD_SELECTED_STATIC && $NOW == $_[0] ) {
    $SAFE_WORLD_SELECTED_STATIC = undef ;
    return 1 ;
  }
  return ;
}

########
# EVAL #
########

sub eval {

  if ( $_[0]->{WORLD_SHARED} && !$_[0]->{DESTROIED} && $NOW != $_[0] ) {
    $_[0]->warn("Don't evaluate inside a linked pack (shared with $_[0]->{WORLD_SHARED})! Please unlink first." , 1) ;
  }
  elsif ( $_[0]->{EXIT} && !$_[0]->{DESTROIED} && $NOW != $_[0] ) {
    $_[0]->warn("Can't evaluate after exit!" , 1) ;
    return ;
  }

  ##print "[[$_[1]]]\n" ;

  if ( $MAIN_STASH != *{"main::"}{HASH} ) {
  ##if ( $_[0]->{INSIDE} ) {
    ##print STDOUT "EVAL>> INSIDE [[ $_[1] ]]\n" ;
    ++$EVALX ;
    
    if ( wantarray ) {
      my @__HPL_ReT__ = eval("no strict;\@_ = () ; package main ; $_[1]") ;
      $NOW->warn($@ , 1) if $@ ; ## $_[0] is undef by @_ = () ;
      return @__HPL_ReT__ ;
    }
    else {
      my $__HPL_ReT__ = eval("no strict;\@_ = () ; package main ; $_[1]") ;
      $NOW->warn($@ , 1) if $@ ; ## $_[0] is undef by @_ = () ;
      return $__HPL_ReT__ ;
    }
  }
  else {
    ##print STDOUT "EVAL>> OUT >> ". \@{'_'} ."\n" ;
    
    my $SAFE_WORLD_selected ;
    if ( $NOW != $_[0] ) {
      $SAFE_WORLD_selected = $SCOPE_Safe_World_select->NEW($_[0]) ; ##Safe::World::select->new($_[0]) ;
    }
    
    $NOW->{INSIDE} = 1 ;
    
    if ( wantarray ) {
      my @ret = $NOW->{SAFE}->reval($_[1]) ;    
      $NOW->warn($@ , 1) if $@ ;
      $NOW->{INSIDE} = 0 ;
      return @ret ;
    }
    else {
      my $ret = $NOW->{SAFE}->reval($_[1]) ;
      $NOW->warn($@ , 1) if $@ ;
      $NOW->{INSIDE} = 0 ;
      return $ret ;
    }
  }
}

################
# EVAL_NO_WARN #
################

sub eval_no_warn {
  if ( $_[0]->{WORLD_SHARED} && !$_[0]->{DESTROIED} && $NOW != $_[0] ) {
    $_[0]->warn("Don't evaluate inside a linked pack (shared with ". join(", ", @{$_[0]->{WORLD_SHARED}}) .")! Please unlink first." , 1) ;
  }
  elsif ( $_[0]->{EXIT} && !$_[0]->{DESTROIED} && $NOW != $_[0] ) {
    $_[0]->warn("Can't evaluate after exit!" , 1) ;
    return ;
  }
  
  no warnings ;
  local $^W = 0 ;
  $IGNORE_EXIT = 1 ;
  
  my %__SAVE_SIGS__ ;
  
  $__SAVE_SIGS__{warn} = $SIG{__WARN__} ;
  $__SAVE_SIGS__{die} = $SIG{__DIE__} ;
  
  $SIG{__WARN__} = sub {} ;
  $SIG{__DIE__} = sub {} ;
  
  $_[0]->{TIESTDERR}->block if $_[0]->{TIESTDERR} ;

  if ( $MAIN_STASH != *{"main::"}{HASH} ) {
  #if ( $_[0]->{INSIDE} ) {
    ++$EVALX ;
    if ( wantarray ) {
      my @__HPL_ReT__ = eval("no strict;\@_ = () ; package main ; $_[1]") ;
      $SIG{__WARN__} = $__SAVE_SIGS__{warn} ; $SIG{__DIE__} = $__SAVE_SIGS__{die} ; $IGNORE_EXIT = undef ; $NOW->{TIESTDERR}->unblock if $NOW->{TIESTDERR} ;
      return @__HPL_ReT__ ;
    }
    else {
      my $__HPL_ReT__ = eval("no strict;\@_ = () ; package main ; $_[1]") ;
      $SIG{__WARN__} = $__SAVE_SIGS__{warn} ; $SIG{__DIE__} = $__SAVE_SIGS__{die} ; $IGNORE_EXIT = undef ; $NOW->{TIESTDERR}->unblock if $NOW->{TIESTDERR} ;
      return $__HPL_ReT__ ;
    }
  }
  else {
    my $SAFE_WORLD_selected ;
    if ( $NOW != $_[0] ) {
      $SAFE_WORLD_selected = $SCOPE_Safe_World_select->NEW($_[0]) ; ##Safe::World::select->new($_[0]) ;
    }
    
    $NOW->{INSIDE} = 1 ;
    
    if ( wantarray ) {
      my @ret = $NOW->{SAFE}->reval($_[1]) ;    
      $NOW->{INSIDE} = 0 ;
      $SIG{__WARN__} = $__SAVE_SIGS__{warn} ; $SIG{__DIE__} = $__SAVE_SIGS__{die} ; $IGNORE_EXIT = undef ; $NOW->{TIESTDERR}->unblock if $NOW->{TIESTDERR} ;
      return @ret ;
    }
    else {
      my $ret = $NOW->{SAFE}->reval($_[1]) ;
      $NOW->{INSIDE} = 0 ;
      $SIG{__WARN__} = $__SAVE_SIGS__{warn} ; $SIG{__DIE__} = $__SAVE_SIGS__{die} ; $IGNORE_EXIT = undef ; $NOW->{TIESTDERR}->unblock if $NOW->{TIESTDERR} ;
      return $ret ;
    }
  }
}

#############
# EVAL_PACK #
#############

sub eval_pack { $_[0]->eval("package $_[1] ; $_[2]") ;}

#############
# EVAL_ARGS #
#############

sub eval_args {
  my $this = shift ;
  my $code = shift ;

  my $tmp = $_ ;
  $_ = \@_ ;
  
  if ( wantarray ) {
    my @ret = $this->eval("\@_=\@{\$_};\$_=undef; $code") ;
    $_ = $tmp ;
    return @ret ;
  }
  else {
    my $ret = $this->eval("\@_=\@{\$_};\$_=undef; $code") ;
    $_ = $tmp ;
    return $ret ;
  }
}

##################
# EVAL_PACK_ARGS #
##################

sub eval_pack_args {
  my $this = shift ;
  my $pack = shift ;
  my $code = shift ;

  if ( @_ ) {
    return $this->eval_args("package $pack ; $code" , @_) ;
  }
  else {
    return $this->eval("package $pack ; $code") ;
  }
}

########
# CALL #
########

sub call {
  my $this = shift ;
  my $sub = shift ;
  
  my $tmp = $_ ;
  $_ = \@_ ;
  
  my ( @ret , $ret ) ;
  
  if ( wantarray ) { @ret = $this->eval("return $sub(\@{\$_}) ;") ;}
  else { $ret = $this->eval("return $sub(\@{\$_}) ;") ;}

  $_ = $tmp ;
  
  return( @ret ) if wantarray ;
  return $ret ;
}

#######
# GET #
#######

sub get {
  my $this = shift ;
  my $var = shift ;
  
  my $pack = $this->{ROOT} ;
  
  my ($var_tp,$var_name,$var_more) = ( $var =~ /^\s*([\$\@\%\*])([\w:]+)(.*)\s*$/s );
  
  if ( $var_more ) { $var_tp = '' ;}
  
  if    ($var_tp eq '$') { return ${$pack.'::'.$var_name} ;}
  elsif ($var_tp eq '@') { return @{$pack.'::'.$var_name} ;}
  elsif ($var_tp eq '%') { return %{$pack.'::'.$var_name} ;}
  elsif ($var_tp eq '*') { return *{$pack.'::'.$var_name} ;}
  else { return $this->eval($var) ;}

  return ;
}

############
# GET_FROM #
############

sub get_from {
  my $this = shift ;
  my $pack = shift ;
  my $var = shift ;
  
  $pack =~ s/[:\.]+/::/gs ;
  return if $pack !~ /^\w+(?:::\w+)*(?:::)?$/s ;
  
  my ($var_tp,$var_name,$var_more) = ( $var =~ /^\s*([\$\@\%\*])([\w:]+)(.*)\s*$/s );
  
  if ( !$var_tp ) { return $this->eval("package $pack; $var") ;}
  
  my $varfull = "$var_tp$pack\::$var_name$var_more" ;
  return $this->get($varfull) ;
}

###########
# GET_REF #
###########

sub get_ref {
  my $this = shift ;
  my ( $varfull ) = @_ ;
  
  my $pack = $this->{ROOT} ;
  
  my ($var_tp,$var) = ( $varfull =~ /([\$\@\%\*])(\S+)/ ) ;
  $var =~ s/^{'(\S+)'}$/$1/ ;
  $var =~ s/^main::// ;

  if ($var_tp eq '$') { return \${$pack.'::'.$var} ;}
  elsif ($var_tp eq '@') { return \@{$pack.'::'.$var} ;}
  elsif ($var_tp eq '%') { return \%{$pack.'::'.$var} ;}
  elsif ($var_tp eq '*') { return \*{$pack.'::'.$var} ;}
  else                   { ++$EVALX ; return eval("package $pack ; \\$varfull") ;}
}

################
# GET_REF_COPY #
################

sub get_ref_copy {
  my $this = shift ;
  my ( $varfull ) = @_ ;
  
  my $pack = $this->{ROOT} ;
  
  my ($var_tp,$var) = ( $varfull =~ /([\$\@\%\*])(\S+)/ ) ;
  $var =~ s/^{'(\S+)'}$/$1/ ;
  $var =~ s/^main::// ;

  if ($var_tp eq '$') {
    my $scalar = ${$pack.'::'.$var} ;
    return \$scalar ;
  }
  elsif ($var_tp eq '@') { return [@{$pack.'::'.$var}] ;}
  elsif ($var_tp eq '%') { return {%{$pack.'::'.$var}} ;}
  elsif ($var_tp eq '*') { return \*{$pack.'::'.$var} ;}
  else                   { ++$EVALX ; return eval("package $pack ; \\$varfull") ;}
}

#######
# SET #
#######

sub set {
  my $this = shift ;
  my ( $var , undef , $no_parse_ref) = @_ ;
  
  my $SAFE_WORLD_selected ;
  if ( $NOW != $this ) {
    $SAFE_WORLD_selected = $SCOPE_Safe_World_select->NEW($this) ; ## Safe::World::select->new($this) ;
  }
  
  my $pack = $this->{ROOT} ;
  
  my ($var_tp,$var_name) = ( $var =~ /^([\$\@\%\*])(.*)/s );
  
  my $val = (ref($_[1])) ? $_[1] : ( $_[1] eq '' ? \undef : \$_[1]) ;
  
  if ($var_tp eq '$') {
    if    (!$no_parse_ref && ref($val) eq 'SCALAR') { ${$pack.'::'.$var_name} = ${$val} ;}
    else                                            { ${$pack.'::'.$var_name} = $val ;}
  }
  elsif ($var_tp eq '@') {
    if    (!$no_parse_ref && ref($val) eq 'ARRAY') { @{$pack.'::'.$var_name} = @{$val} ;}
    elsif (!$no_parse_ref && ref($val) eq 'HASH')  { @{$pack.'::'.$var_name} = %{$val} ;}
    else                                           { @{$pack.'::'.$var_name} = $val ;}
  }
  elsif ($var_tp eq '%') {
    if    (!$no_parse_ref && ref($val) eq 'HASH')  { %{$pack.'::'.$var_name} = %{$val} ;}
    elsif (!$no_parse_ref && ref($val) eq 'ARRAY') { %{$pack.'::'.$var_name} = @{$val} ;}
    else                                           { %{$pack.'::'.$var_name} = $val ;}
  }
  elsif ($var_tp eq '*') {
    if    (ref($val) eq 'GLOB')  { *{$pack.'::'.$var_name} = $val ;}
    else                         { *{$pack.'::'.$var_name} = \*{$val} ;}
  }
  else {
    ++$EVALX ; eval("$var_tp$pack\::$var_name = $val ;") ;
  }

  return ;
}

############
# SET_VARS #
############

sub set_vars {
  my $this = shift ;
  my ( %vars ) = @_ ;
  
  my $SAFE_WORLD_selected ;
  if ( $NOW != $this ) {
    $SAFE_WORLD_selected = $SCOPE_Safe_World_select->NEW($this) ; ## Safe::World::select->new($this) ;
  }
  
  my $pack = $this->{ROOT} ;
  
  my ($var_tp,$var) ;
  
  foreach my $Key ( keys %vars ) {
    ($var_tp,$var) = ( $Key =~ /([\$\@\%\*])(\S+)/ );
    $var =~ s/^{'(\S+)'}$/$1/ ;
    $var =~ s/^main::// ;

    if ($var_tp eq '$') {
      if    (ref($vars{$Key}) eq 'SCALAR') { ${$pack.'::'.$var} = ${$vars{$Key}} ;}
      else                                 { ${$pack.'::'.$var} = $vars{$Key} ;}
    }
    elsif ($var_tp eq '@') {
      if    (ref($vars{$Key}) eq 'ARRAY') { @{$pack.'::'.$var} = @{$vars{$Key}} ;}
      elsif (ref($vars{$Key}) eq 'HASH')  { @{$pack.'::'.$var} = %{$vars{$Key}} ;}
      else                                { @{$pack.'::'.$var} = $vars{$Key} ;}
    }
    elsif ($var_tp eq '%') {
      if    (ref($vars{$Key}) eq 'HASH')  { %{$pack.'::'.$var} = %{$vars{$Key}} ;}
      elsif (ref($vars{$Key}) eq 'ARRAY') { %{$pack.'::'.$var} = @{$vars{$Key}} ;}
      else                                { %{$pack.'::'.$var} = $vars{$Key} ;}
    }
    elsif ($var_tp eq '*') {
      if    (ref($vars{$Key}) eq 'GLOB')  { *{$pack.'::'.$var} = $vars{$Key} ;}
      else                                { *{$pack.'::'.$var} = \*{$vars{$Key}} ;}
    }
    else { ++$EVALX ; eval("$var_tp$pack\::$var = \$vars{\$Key} ;") ;}
  }
  
  return 1 ;
}

##############
# SHARE_VARS #
##############

sub share_vars {
  my $this = shift ;
  if ( $this->{INSIDE} ) { return ;}
  
  my ( $from_pack , $vars ) = @_ ;
  if ( ref($vars) ne 'ARRAY' ) { return ;}
  
  $from_pack =~ s/^:+//s ;
  $from_pack =~ s/:+$//s ;

  $this->{SAFE}->share_from($from_pack , $vars) ;
  
  foreach my $var ( @$vars ) {
    next if ($var eq '$_' || $var eq '$|' || $var eq '$@' || $var eq '$!') ;
    
    if ( $var !~ /^\W[\w:]+$/ ) {
      my ($t , $n) = ( $var =~ /^(\W)(.*)/s );
      $var = "$t\{'$from_pack\::$n'}" ;
    }
    else {
      $var =~ s/^(\W)/$1$from_pack\::/ ;    
    }

    $this->{SHARING}{$var} = { IN => undef , OUT => undef } ;
  }

  return 1 ;
}

################
# UNSHARE_VARS #
################

sub unshare_vars {
  my $this = shift ;
  if ( $this->{INSIDE} ) { return ;}
    
  my $pack = $this->{ROOT} ;
  
  my ($NULL , @NULL , %NULL) ;
  local(*NULL) ;
  
  my %vars = map { $_ => 1 } ( keys %{ $this->{SHARING} } ) ;
  my @vars = sort { ($a =~ /^\*/ ? 1 : -1 ) } keys %vars ;
  
  foreach my $var (@vars) {
    my ($var_tp,$name) = ( $var =~ /([\$\@\%\*])(\S+)/ );
    $name =~ s/^{'(\S+)'}$/$1/ ;
    $name =~ s/^main::// ;
    
    next if $this->{DONOT_CLEAN}{$name} ;
    
    if    ($var_tp eq '$') { *{$pack.'::'.$name} = \$NULL ;}
    elsif ($var_tp eq '@') { *{$pack.'::'.$name} = \@NULL ;}
    elsif ($var_tp eq '%') { *{$pack.'::'.$name} = \%NULL ;}
    elsif ($var_tp eq '*') { *{$pack.'::'.$name} = \*NULL ;}
  }
  
  return 1 ;
}

##############
# TRACK_VARS #
##############

sub track_vars {
  my $this = shift ;
  my $world = ref($_[0]) ? shift : undef ;
  my $world_dependency = ($world && ref($_[0])) ? shift : undef ;
  $world ||= $this ;
      
  my ( @vars ) = @_ ;
  
  my $root = $world->{ROOT} ;
  
  if ( $world_dependency ) {
    $this->{TRACK_DEPENDENCIES}{$root} = $world_dependency->{ROOT} ;
  }
  
  if ( @vars ) {
    my $set_defaults ;
    foreach my $var ( @vars ) {
      if ( $var =~ /^:def\w*$/ ) { $set_defaults = 1 ; next ;}
      
      ##print STDOUT ">> $var\n" ;
    
      my ($t , $n) = ( $var =~ /^(\W)(.*)/s ) ;
      $this->{TRACK_VARS}{$root}{$n}{g} = \*{$root.'::'.$n} if !$this->{TRACK_VARS}{$root}{$n}{g} ;
      
      next if $this->{TRACK_VARS}{$root}{$n}{$t} ;
      
      push( @{$this->{TRACK_VARS_LIST}}  , $var) if $world == $this ;
      
      if ( $root eq $this->{ROOT} && $t ne '>' && $t ne '<' && $t ne '*' ) {
        $this->{TRACK_VARS}{$root}{$n}{$t} = \${$root.'::'.$n} if $t eq '$' ;
        $this->{TRACK_VARS}{$root}{$n}{$t} = \@{$root.'::'.$n} if $t eq '@' ;
        $this->{TRACK_VARS}{$root}{$n}{$t} = \%{$root.'::'.$n} if $t eq '%' ;
      }
      elsif ( $t eq '*' ) {
        my $glob = 'G' . ++$TRACK_GLOB_X ;
        push( @{$this->{TRACK_GLOBS}} , $glob) ;
        *{$TRACK_GLOBS_BASE . $glob} = \*{$root.'::'.$n} ;
        $this->{TRACK_VARS}{$root}{$n}{$t} = \*{$TRACK_GLOBS_BASE . $glob} ;
      }
      else {
        $this->{TRACK_VARS}{$root}{$n}{$t} = 1 ;
      }
    }
    
    if ( $set_defaults && (!$this->{TRACK_VARS_DEF} || $world != $this) ) {
      $this->{TRACK_VARS_DEF} = 1 if $world == $this ;
      $this->track_vars($world , @TRACK_VARS_DEF) ;
    }
  }
  
  return @{$this->{TRACK_VARS_LIST}} ;
}

####################
# SET_TRACKED_VARS #
####################

sub set_tracked_vars {
  my $this = shift ;
  my $track_vars = ref($_[0]) eq 'HASH' ? shift : $this->{TRACK_VARS} ;
  return if !$track_vars ;
  
  my ( $pack_root ) = @_ ;
  $pack_root = $pack_root->{ROOT} if ref($pack_root) ;

  $pack_root ||= $this->{ROOT} ;
  
  ##print main::STDOUT "====================== $this->{ROOT} >> $pack_root\n" ;
  
  foreach my $track_root ( keys %$track_vars ) {
    
    if (
      $this->{TRACK_ONLY_LINKED}{$track_root}
      &&
      (
        ( $this->{TRACK_ONLY_LINKED}{$track_root} eq '1' && !$this->{LINKED_WORLDS}{$track_root} )
        ||
        ( $this->{TRACK_ONLY_LINKED}{$track_root} ne '1' && !$this->{LINKED_WORLDS}{ $this->{TRACK_ONLY_LINKED}{$track_root} } )
      )
    ) { next ;}
  
    if ($track_root ne $pack_root) {
      *{"$pack_root\::$track_root\::"} = \*{"$pack_root\::"} ;
      ##print main::STDOUT "LINK>> $pack_root\::$track_root >> $pack_root\n" ;
      _rebless($track_root , $pack_root) ;
    }
  
    foreach my $n ( keys %{ $$track_vars{$track_root} } ) {
      my $glob = $$track_vars{$track_root}{$n}{g} ;
      
      ##print main::STDOUT "TRACK>> $track_root\::$n >> $pack_root\::$n \n" ;
      
      if ( $$track_vars{$track_root}{$n}{'*'} ) {
        *$glob = \*{$pack_root.'::'.$n} ;
      }
      elsif ( $$track_vars{$track_root}{$n}{'>'} ) {
        if ($] < 5.007) {
          untie *{"$track_root\::$n"} ;
          tie( *$glob => 'Safe::World::stdoutsimple' , $track_root , \*{"$pack_root\::$n"} ) ;
        }
        else {
          *$glob = \*{"$pack_root\::$n"} ;
        }
      }
      elsif ( $$track_vars{$track_root}{$n}{'<'} ) {
        *$glob = \*{"$pack_root\::$n"} ;
      }

      *$glob = \${$pack_root.'::'.$n} if $$track_vars{$track_root}{$n}{'$'} ;
      *$glob = \@{$pack_root.'::'.$n} if $$track_vars{$track_root}{$n}{'@'} ;
      *$glob = \%{$pack_root.'::'.$n} if $$track_vars{$track_root}{$n}{'%'} ;
    }
  }

}

######################
# CLEAN_TRACKED_VARS #
######################

sub clean_tracked_vars {
  my $this = shift ;
  return if !$this->{TRACK_VARS} ;
  
  my ($NULL , @NULL , %NULL) ;  
  local(*NULL) ;
  
  foreach my $track_root ( keys %{ $this->{TRACK_VARS} } ) {
  
    if (
      $this->{TRACK_ONLY_LINKED}{$track_root}
      &&
      (
        ( $this->{TRACK_ONLY_LINKED}{$track_root} eq '1' && !$this->{LINKED_WORLDS}{$track_root} )
        ||
        ( $this->{TRACK_ONLY_LINKED}{$track_root} ne '1' && !$this->{LINKED_WORLDS}{ $this->{TRACK_ONLY_LINKED}{$track_root} } )
      )
    ) { next ;}
  
    foreach my $n ( keys %{ $this->{TRACK_VARS}{$track_root} } ) {
      my $glob = $this->{TRACK_VARS}{$track_root}{$n}{g} ;
      
      my $ref ;
            
      if ( $ref = $this->{TRACK_VARS}{$track_root}{$n}{'*'} ) {
        *$glob = \*$ref ;
      }
      elsif ( $this->{TRACK_VARS}{$track_root}{$n}{'>'} ) {
        if ( tied *{"$track_root\::$n"} ) {
          untie( *$glob ) ;
        }
        else {
          *$glob = \*NULL ;
        }
      }
      elsif ( $this->{TRACK_VARS}{$track_root}{$n}{'<'} ) {
        *$glob = \*NULL ;
      }
      
      if ( $ref = $this->{TRACK_VARS}{$track_root}{$n}{'$'} ) {
        *$glob = $ref eq '1' ? \$NULL : $ref ;
      }
      if ( $ref = $this->{TRACK_VARS}{$track_root}{$n}{'@'} ) {
        *$glob = $ref eq '1' ? \@NULL : $ref ;
      }
      if ( $ref = $this->{TRACK_VARS}{$track_root}{$n}{'%'} ) {
        *$glob = $ref eq '1' ? \%NULL : $ref ;
      }

    }
    
    if ( $this->{TRACK_DEPENDENCIES}{$track_root} || $track_root =~ /CACHE/ ) {
      my $root = $this->{TRACK_DEPENDENCIES}{$track_root} || $track_root ;
      my ($base , $leaf) = ( "main::$root\::" =~ /^(.*::)(\w+::)$/ ) ;
      if ( !defined *{$base}{HASH}{$leaf} ) {
        delete $this->{TRACK_VARS}{$root} ;
        delete $this->{TRACK_VARS}{$track_root} ;
        delete $this->{TRACK_DEPENDENCIES}{$track_root} ;
      }
    }

  }
  
  return 1 ;
}

######################
# CHECK_TRACK_DEPEND #
######################

sub check_track_depend {
  my $this = shift ;
  return if !$this->{TRACK_VARS} ;
  
  foreach my $track_root ( keys %{ $this->{TRACK_VARS} } ) {

    if ( $this->{TRACK_DEPENDENCIES}{$track_root} || $track_root =~ /CACHE/ ) {
      my $root = $this->{TRACK_DEPENDENCIES}{$track_root} || $track_root ;
      my ($base , $leaf) = ( "main::$root\::" =~ /^(.*::)(\w+::)$/ ) ;
      if ( !defined *{$base}{HASH}{$leaf} ) {
        delete $this->{TRACK_VARS}{$root} ;
        delete $this->{TRACK_VARS}{$track_root} ;
        delete $this->{TRACK_DEPENDENCIES}{$track_root} ;
      }
    }

  }
  
  return 1 ;
}

#############
# LINK_PACK #
#############

sub link_pack {
  my $this = shift ;
  if ( $this->{INSIDE} ) { return ;}
  my ( $pack ) = @_ ;
  
  my $pack_alise = $pack ;
  $pack_alise =~ s/^(?:$COMPARTMENT_NAME|$COMPARTMENT_NAME_CACHE)\d+::// ;
  
  my @packs = scanpacks( "$this->{ROOT}::$pack_alise" ) ;
  
  foreach my $packs_i ( reverse sort @packs ) {
    next if $packs_i eq "$this->{ROOT}::$pack_alise" ;
    my $pack_link = $packs_i ;
    $pack_link =~ s/^(?:$COMPARTMENT_NAME|$COMPARTMENT_NAME_CACHE)\d+::(?:$pack_alise:*)?// ;
    $pack_link = "$pack\::$pack_link" ;
    *{"$packs_i\::"} = *{"$pack_link\::"} ;
  }

  *{"$this->{ROOT}\::$pack_alise\::"} = *{"$pack\::"} ;
  
  $this->{LINKED_PACKS}{$pack_alise} = 1 ;
    
  return 1 ;
}

###############
# UNLINK_PACK #
###############

sub unlink_pack {
  my $this = shift ;
  if ( $this->{INSIDE} ) { return ;}
  my ( $pack ) = @_ ;
  
  my $packname = $this->{ROOT} ;

  *{"$packname\::$pack\::"} = *{"$packname\::PACKNULL::"} ;
  undef %{"$packname\::$pack\::"} ;
  undef *{"$packname\::$pack\::"} ;
  return 1 ;
}

###################
# UNLINK_PACK_ALL #
###################

sub unlink_pack_all {
  my $this = shift ;
  if ( $this->{INSIDE} ) { return ;}

  my $packname = $this->{ROOT} ;
  
  if ( $_[0] ) {
    $this->{LINKED_PACKS}{$packname} = 1 ;
    $this->{LINKED_PACKS}{main} = 1 ;
  }

  foreach my $pack ( keys %{$this->{LINKED_PACKS}} ) {
    *{"$packname\::$pack\::"} = *{"$packname\::PACKNULL::"} ;
    undef %{"$packname\::$pack\::"} ;
    undef *{"$packname\::$pack\::"} ;
  }
  
  $this->{LINKED_PACKS} = {} ;
  return 1 ;
}

##################
# SET_SHAREDPACK #
##################

sub set_sharedpack {
  my $this = shift ;
  my ( @packs ) = @_ ;
  
  #$this->track_vars(':defaults') if !$this->{TRACK_VARS_DEF} && !$this->{SHAREDPACK} || !@{$this->{SHAREDPACK}} ;
  
  my @shared_pack = @{$this->{SHAREDPACK}} ;
  my %shared_pack = map { ("$_\::" => 1) } @shared_pack ;
  
  foreach my $packs_i ( @packs ) {
    $packs_i =~ s/[^\w:\.]//gs ;
    $packs_i =~ s/[:\.]+/::/ ;
    $packs_i =~ s/^(?:main)?::// ;
    $packs_i =~ s/::$// ;
    
    next if ($shared_pack{$packs_i} || $packs_i eq '') ;
    
    push(@{$this->{SHAREDPACK}} , $packs_i) ;

    my $pm = $packs_i ;
    $pm =~ s/::/\//g ;
    $pm .= '.pm' ;
    $this->{SHAREDPACK_PM}{$packs_i} = $pm ;
  }
  
  return 1 ;
}

####################
# UNSET_SHAREDPACK #
####################

sub unset_sharedpack {
  my $this = shift ;
  my ( @packs ) = @_ ;

  my %packs = map { ($_ => 1) } @packs ;  
  
  my @sets ;
  foreach my $shared_pack_i ( @{$this->{SHAREDPACK}} ) {
    if ( !$packs{$shared_pack_i} ) { push(@sets , $shared_pack_i) ;}
    else { delete $this->{SHAREDPACK_PM}{$shared_pack_i} ;}
  }
  
  @{$this->{SHAREDPACK}} = @sets ;
  
  return 1 ;
}

##############
# USE_SHARED #
##############

sub use_shared {
  my $this = shift ;
  my $module = shift ;
  
  ##print main::STDOUT "SHARE>> $module\n" ;
  
  my $pm = $module ;
  $pm =~ s/::/\//g ; $pm .= '.pm' ;
  
  my $SAFE_WORLD_selected ;
  if ( $NOW != $this ) {
    $SAFE_WORLD_selected = $SCOPE_Safe_World_select->NEW($this) ; ## Safe::World::select->new($this) ;
  }
  
  my (%new_incs) ;
  
  {
    if ( $INC{$pm} ) { return "Module $module already cached!" ;}
    
    my %packs_prev = map { $_ => 1 } ( scanpacks( $this->{ROOT} ) ) ;
    
    my %inc_now = %INC ;
    
    my $use_cmd = "no strict ; require $module ;" ;
    if ( @_ && join(" ", @_) =~ /\S/s ) {
      $use_cmd .= " $module\::import('$module', qw\0 ". join(" ", @_) ." \0 ) if defined &$module\::import ;" ;
    }
    
    $this->eval_no_warn($use_cmd) ;
    
    if ( $@ ) {
      return "Error on loading $module\n$@" ;
    }
    else {
      foreach my $Key ( keys %INC ) { $new_incs{$Key} = $INC{$Key} if !$inc_now{$Key} && ($Key =~ /^\w.*?\.pm$/) ;}
      
      my @packs_now = scanpacks( $this->{ROOT} ) ;

      foreach my $packs_now_i ( @packs_now ) {
        next if $packs_prev{$packs_now_i} ;
        
        my $pm = $packs_now_i ;
        $pm =~ s/^\Q$this->{ROOT}\E::// ;
        $pm =~ s/::/\//gs ; $pm .= '.pm' ;
        
        next if $new_incs{$pm} ;
        
        my $table = *{"$packs_now_i\::"}{HASH} ;
        next if !%$table ;
        
        my $has_non_pack  ;
        foreach my $Key (sort keys %$table ) {
          if ( $Key !~ /::$/ ) { $has_non_pack = $Key ; last ;}
        }
        next if !$has_non_pack ;
        
        $new_incs{$pm} = '#not_from_file#' ;
      }
    }
  }
  
  my ( %inc , @link_pack ) ;
  
  if ( %new_incs ) {
    my (%base_set , @set_shared) ;
    foreach my $Key ( sort keys %new_incs ) {
      $inc{$Key} = '#shared#' if $new_incs{$Key} ne '#not_from_file#' ;
      $this->{USE_SHARED_INC}{$Key} = ($new_incs{$Key} eq '#not_from_file#') ? 2 : 1 ;
      
      my $module = $Key ;
      $module =~ s/[\\\/]/::/g ;
      $module =~ s/\.pm$// ;

      my @path = split("::" , $module) ;
      
      my $set ;
      while( @path ) {
        if ( $base_set{ join("::", @path) } ) { $set = 1 ; last ;}
        pop (@path) ;
      }
      
      next if $set ;
      $base_set{$module} = 1 ;
      
      push(@set_shared , $module) ;

      push(@link_pack , $this->{ROOT}."::$module") ;
    }
    
    ##print main::STDOUT "SETX>> @set_shared\n" ;
    
    $this->set_sharedpack(@set_shared) ;
  }
  
  return( \@link_pack , \%inc ) ;
}

##############
# LINK_WORLD #
##############

sub link_world {
  my $this = shift ;
  my $world = shift ;
  my $dont_touch_main = shift ;
  
  if ( $this->{INSIDE} || ref($world) ne 'Safe::World' || (!$this->{IS_CACHE} && $world->{WORLD_SHARED}) || $world->{INSIDE} ) { return ;}

  my $world_root = $world->{ROOT} ;
  my $root = $this->{ROOT} ;
  
  $world->track_vars(':defaults') if !$dont_touch_main && !$world->{TRACK_VARS_DEF} ;
  
  ########
  
  my @shared_pack = @{$world->{SHAREDPACK}} ;
  my %shared_pack = map { ("$_\::" => 1) } @shared_pack ;

  my $inc ;
  if ( $NOW == $this ) { $inc = \%INC ;}
  else { $inc = $this->{SHARING}{'%main::INC'}{IN} ;}
  
  my $world_inc ;
  if ( $NOW == $world ) { $world_inc = \%INC ;}
  else { $world_inc = $world->{SHARING}{'%main::INC'}{IN} ;}

  foreach my $shared_pack ( @shared_pack ) {
    if ( !$$inc{ $world->{SHAREDPACK_PM}{$shared_pack} } ) {
      $this->link_pack("$world_root\::$shared_pack") ;
    }
    
    my $base = $shared_pack ;
    $base =~ s/::/\//g ;
    
    foreach my $Key ( keys %$world_inc ) {
      if ( !$this->{USE_SHARED_INC}{$Key} && !$$inc{$Key} && $Key =~ /^(?:auto\/)?\Q$base\E(?:\/|\.)/ ) { $$inc{$Key} = '#shared#' ;}
    }
  }
  
  foreach my $Key ( keys %{ $world->{USE_SHARED_INC} } ) {
    $$inc{$Key} = '#shared#' if $world->{USE_SHARED_INC}{$Key} != 2 ;
  }
  
  ########
  
  if ( !$dont_touch_main ) {
    my $table = *{"$world_root\::"}{HASH} ;
    
    foreach my $Key ( keys %$table ) {
      if ( !$shared_pack{$Key} && $$table{$Key} =~ /^\*(?:main|$world_root)::/ && $Key !~ /^(?:.*?::)$/ && $Key !~ /[^\w:]/s) {
        next if tied( *{"$world_root\::$Key"} ) ;
        *{"$world_root\::WORLDSHARE::$Key"} = \${"$world_root\::$Key"} ;
        *{"$world_root\::WORLDSHARE::$Key"} = \@{"$world_root\::$Key"} ;
        *{"$world_root\::WORLDSHARE::$Key"} = \%{"$world_root\::$Key"} ;
        *{"$world_root\::WORLDSHARE::$Key"} = \&{"$world_root\::$Key"} if defined &{"$world_root\::$Key"} ;
        *{"$world_root\::WORLDSHAREGLOBS::$Key"} = \*{"$world_root\::$Key"} ;
        
        *{"$world_root\::$Key"} = \${"$root\::$Key"} ;
        *{"$world_root\::$Key"} = \@{"$root\::$Key"} ;
        *{"$world_root\::$Key"} = \%{"$root\::$Key"} ;
        *{"$world_root\::$Key"} = \&{"$root\::$Key"} if defined &{"$root\::$Key"} ;
        *{"$world_root\::$Key"} = \*{"$root\::$Key"} ;
        #$$table{$Key} = "*$root\::$Key" ;
      }
    }
  }
  
  ########
  
  $this->{LINKED_WORLDS}{ $world->{ROOT} } = 1 ;
  $world->{LINKED_WORLDS}{ $this->{ROOT} } = 1 ;  
  
  $world->set_tracked_vars($this) if !$dont_touch_main ;
  
  ########
  
  push(@{$world->{WORLD_SHARED}} , $root) ;
  
  $WORLDS_LINKS{$this}{$world} = $world ;
  
  return 1 ;
}

################
# UNLINK_WORLD #
################

sub unlink_world {
  my $this = shift ;
  my $world = shift ;
  my $dont_touch_main = shift ;
  
  if ( $this->{INSIDE} || ref($world) ne 'Safe::World' || !$world->{WORLD_SHARED} || $world->{INSIDE} ) { return ;}

  my $world_root = $world->{ROOT} ;
  my $root = $this->{ROOT} ;
  
  ########
  
  my @shared_pack = @{$world->{SHAREDPACK}} ;
  my %shared_pack = map { ("$_\::" => 1) } @shared_pack ;

  my $inc ;
  if ( $NOW == $this ) { $inc = \%INC ;}
  else { $inc = $this->{SHARING}{'%main::INC'}{IN} ;}
  
  my $world_inc ;
  if ( $NOW == $world ) { $world_inc = \%INC ;}
  else { $world_inc = $world->{SHARING}{'%main::INC'}{IN} ;}

  my $track_this ;

  foreach my $shared_pack ( @shared_pack ) {
    $this->unlink_pack($shared_pack) ;
    
    my $base = $shared_pack ;
    $base =~ s/::/\//g ;
    foreach my $Key ( keys %$inc ) {
      if ( $Key =~ /^(?:auto\/)?\Q$base\E(?:\/|\.)/ ) {
        if (!$$world_inc{$Key} && $$inc{$Key} ne '#shared#' && $world->{USE_SHARED_INC}{$Key} != 2 && $world->{USE_SHARED_INC}{"$base.pm"} != 2) {
          $$world_inc{$Key} = $$inc{$Key} ;
          $track_this = 1 ;
        }
        delete $$inc{$Key} ;
      }
      elsif ( $$inc{$Key} eq '#shared#' ) { delete $$inc{$Key} ;}
    }
  }
  
  ########
  
  $world->clean_tracked_vars if !$dont_touch_main ;
  
  delete $this->{LINKED_WORLDS}{ $world->{ROOT} } ;
  delete $world->{LINKED_WORLDS}{ $this->{ROOT} } ;
  
  if ( !$dont_touch_main && $track_this ) {
    $world->track_vars( $this , ':defaults' ) ;
  }
  
  ########
  
  if ( !$dont_touch_main ) {
    my $table = *{"$world_root\::"}{HASH} ;
    
    foreach my $Key ( keys %$table ) {
      if ( !$shared_pack{$Key} && $$table{$Key} =~ /^\*(?:main|$root)::(.*)/ && $Key !~ /^(?:.*?::)$/ && $Key !~ /[^\w:]/s) {
        next if tied( *{"$world_root\::$Key"} ) ;
  
        #$$table{$Key} = "*$world_root\::WORLDSHARE::$1" ;
        *{"$world_root\::$Key"} = \*{"$world_root\::WORLDSHAREGLOBS::$Key"} ;
        
        *{"$world_root\::$Key"} = \${"$world_root\::WORLDSHARE::$Key"} ;
        *{"$world_root\::$Key"} = \@{"$world_root\::WORLDSHARE::$Key"} ;
        *{"$world_root\::$Key"} = \%{"$world_root\::WORLDSHARE::$Key"} ;
        *{"$world_root\::$Key"} = \&{"$world_root\::WORLDSHARE::$Key"} if defined &{"$world_root\::WORLDSHARE::$Key"} ;
      }
    }
  }
  
  ########
  
  pop @{$world->{WORLD_SHARED}} ;
  $world->{WORLD_SHARED} = undef if !@{$world->{WORLD_SHARED}} ;
  
  delete $WORLDS_LINKS{$this}{$world} ;
  
  $world->track_vars(':defaults') if !$dont_touch_main && !$world->{TRACK_VARS_DEF} && $world->{SHAREDPACK} && @{$world->{SHAREDPACK}} ;
  
  return 1 ;
}

#####################
# UNLINK_ALL_WORLDS #
#####################

sub unlink_all_worlds {
  my $this = shift ;
  if ( $this->{INSIDE} || !$WORLDS_LINKS{$this} ) { return ;}
  
  my @unlink_packs ;
  
  foreach my $Key ( keys %{ $WORLDS_LINKS{$this} } ) {
    push(@unlink_packs , $WORLDS_LINKS{$this}{$Key}->{ROOT} ) ;
    $this->unlink_world( $WORLDS_LINKS{$this}{$Key} ) ;
  }
  
  delete $WORLDS_LINKS{$this} ;
  
  return @unlink_packs ;
}

#############
# SCANPACKS #
#############

sub scanpacks {
  if ( ref($_[0]) && ( $_[0]->{INSIDE} || $NOW == $_[0] ) ) { return ;}
  my $scan = $SCOPE_Safe_World_ScanPack->NEW( ref($_[0]) ? $_[0]->{ROOT} : $_[0] ) ; ## Safe::World::ScanPack->new( ref($_[0]) ? $_[0]->{ROOT} : $_[0] ) ;
  return reverse $scan->packages ;
}

##################
# SCANPACK_TABLE #
##################

sub scanpack_table {
  my $this = ref($_[0]) ? shift : undef ;
  if ( ref($this) && ( $this->{INSIDE} || $NOW == $this ) ) { return ;}
  
  my ( $packname ) = @_ ;
  
  $packname = $this->{ROOT} . "::$packname" if $this ;
  
  $packname .= '::' unless $packname =~ /::$/ ;
  no strict "refs" ;
  my $package = *{$packname}{HASH} ;
  return unless defined $package ;
  
  no warnings ;
  local $^W = 0 ;
  
  my @table ;
  
  my $fullname ;
  foreach my $symb ( keys %$package ) {
    $fullname = "$packname$symb" ;
    if ( $symb !~ /::$/ && ($symb !~ /[^\w:]/ || $symb =~ /^\W\w?$/ ) ) {
      my $ok ;
      if (defined $$fullname) { push(@table , "\$$fullname") ; $ok = 1 ;}
      if (defined %$fullname) { push(@table , "\%$fullname") ; $ok = 1 ;}
      if (defined @$fullname) { push(@table , "\@$fullname") ; $ok = 1 ;}
      if (defined &$fullname) { push(@table , "\&$fullname") ; $ok = 1 ;}
      if (*{$fullname}{IO} && fileno $fullname) {
        push(@table , "\*$fullname") ; $ok = 1 ;
      }
      if (!$ok) { push(@table , "\$$fullname") ;}
    }
  }

  return( @table ) ;
}

########
# WARN #
########

sub warn {
  my $this = shift ;
  return if $this->{NO_IO} ;
  
  return if ($this->{TIESTDERR}->{LAST_ERROR} eq $_[0] || $_[0] =~ /#CORE::GLOBAL::exit#/ ) ;
  
  my @call = caller($_[1]) ;
  
  my %keys = (
  package  => 0 ,
  file     => 1 ,
  line     => 2 ,
  sub      => 3 ,
  evaltext => 6 ,
  ) ;
  
  my $caller ;
  
  foreach my $Key (sort { $keys{$a} <=> $keys{$b} } keys %keys ) {
    my $val = $call[$keys{$Key}] ;
    next if $val eq '' ;
    my $s = '.' x (7 - length($Key)) ;
    $val = "\"$val\"" if $val =~/\s/s ;
    $caller .= "  $Key$s: $val\n" ;
  }
  
  #my $caller = qq`package="$call[0]" ; file="$call[1]" ; line="$call[2]" ; sub="$call[3]" ; evaltext="$call[6]"`;
  
  $this->print_stderr("$_[0] CALLER(\n$caller)\n") ;
}

#########
# PRINT #
#########

sub print {
  my $this = shift ;
  return if $this->{NO_IO} ;
  
  my $SAFE_WORLD_selected ;
  if ( $NOW != $this ) {
    $SAFE_WORLD_selected = $SCOPE_Safe_World_select->NEW($this) ; ## Safe::World::select->new($this) ;
  }
  
  $this->{TIESTDOUT}->print(@_) ;
}

################
# PRINT_STDOUT #
################

sub print_stdout { &print ;}

################
# PRINT_STDERR #
################

sub print_stderr {
  my $this = shift ;
  return if $this->{NO_IO} ;
  
  my $SAFE_WORLD_selected ;
  if ( $NOW != $this ) {
    $SAFE_WORLD_selected = $SCOPE_Safe_World_select->NEW($this) ; ## Safe::World::select->new($this) ;
  }
  
  $this->{TIESTDERR}->print(@_) ;
}

################
# PRINT_HEADER #
################

sub print_header {
  my $this = shift ;
  return if $this->{NO_IO} ;
  
  my $SAFE_WORLD_selected ;
  if ( $NOW != $this ) {
    $SAFE_WORLD_selected = $SCOPE_Safe_World_select->NEW($this) ; ## Safe::World::select->new($this) ;
  }
  
  $this->{TIESTDOUT}->print_headout(@_) ;
}

###################
# REDIRECT_STDOUT #
###################

sub redirect_stdout {
  my $this = shift ;
  return if $this->{NO_IO} ;
  
  my ( $ref ) = @_ ;
  return if ref($ref) ne 'SCALAR' ;
  
  push( @{ $this->{TIESTDOUT}->{REDIRECT_STACK} } , $this->{TIESTDOUT}->{REDIRECT} ) if $this->{TIESTDOUT}->{REDIRECT} ;
  $this->{TIESTDOUT}->{REDIRECT} = $ref ;
}

##################
# RESTORE_STDOUT #
##################

sub restore_stdout {
  my $this = shift ;
  return if $this->{NO_IO} ;
  
  $this->{TIESTDOUT}->{REDIRECT} = @{ $this->{TIESTDOUT}->{REDIRECT_STACK} } ? pop( @{ $this->{TIESTDOUT}->{REDIRECT_STACK} } ) : undef ;
}

#############
# BLOCK IOS #
#############

sub block_stdout { $_[0]->{TIESTDOUT}->block if $_[0]->{TIESTDOUT} ;}
sub unblock_stdout { $_[0]->{TIESTDOUT}->unblock if $_[0]->{TIESTDOUT} ;}

sub block_stderr { $_[0]->{TIESTDERR}->block if $_[0]->{TIESTDERR} ;}
sub unblock_stderr { $_[0]->{TIESTDERR}->unblock if $_[0]->{TIESTDERR} ;}

#########
# FLUSH #
#########

sub flush {
  my $this = shift ;
  return if $this->{NO_IO} ;
  
  my ( $set ) = @_ ;
  
  if ( $#_ == 0 ) {
    if ( $set ) { $this->set('$|',1) ;}
    else { $this->set('$|',0) ;}
  }

  $this->{TIESTDOUT}->flush if $this->{TIESTDOUT} ;
}

###################
# CLOSE_TIESTDOUT #
###################

sub close_tiestdout {
  my $this = shift ;
  return if $this->{NO_IO} ;
  
  my $SAFE_WORLD_selected ;
  if ( $NOW != $this ) {
    $SAFE_WORLD_selected = $SCOPE_Safe_World_select->NEW($this) ; ## Safe::World::select->new($this) ;
  }

  $this->{TIESTDOUT}->CLOSE ;
}

###################
# CLOSE_TIESTDERR #
###################

sub close_tiestderr {
  my $this = shift ;
  return if $this->{NO_IO} ;
  
  my $SAFE_WORLD_selected ;
  if ( $NOW != $this ) {
    $SAFE_WORLD_selected = $SCOPE_Safe_World_select->NEW($this) ; ## Safe::World::select->new($this) ;
  }

  $this->{TIESTDERR}->CLOSE ;
}

#########
# CLOSE #
#########

sub close {
  my $this = shift ;

  $this->{EXIT} = undef ;
  
  $this->close_tiestdout ;
  $this->close_tiestderr ;  

  $this->set('$SAFEWORLD',\undef) ;
  $this->flush(1) ;
  
  $this->{EXIT} = 1 ;
  
  return 1 ;
}

sub _root_is_tracked {
  my ( @roots ) = @_ ;

  foreach my $world_root ( keys %{ $SAFEWORLDS_TABLE->{POOL} } ) {
    my $world = $SAFEWORLDS_TABLE->{POOL}{$world_root} ;
    if ( !$world ) {
      delete $SAFEWORLDS_TABLE->{POOL}{$world_root} ;
      next ;
    }
    
    foreach my $track_root ( %{ $world->{TRACK_VARS} } ) {
      foreach my $roots_i ( $world_root , @roots ) {
        return 1 if $track_root eq $roots_i ;
      }
    } 
  }  
  return undef ;
}

###########
# DESTROY #
###########

sub DESTROY {
  my $this = shift ;
  return if $this->{DESTROIED} ;
  
  ##my @call = caller(1) ;
  ##print main::STDOUT "DESTSAFE>> $this->{ROOT} [@call]\n" ;

  $this->unlink_all_worlds ;
  $this->close ;
  
  untie *{"$this->{ROOT}\::STDOUT"} ;
  untie *{"$this->{ROOT}\::STDERR"} ;
  
  $this->clean_tracked_vars ;
  
  if ( ref($this->{TRACK_GLOBS}) eq 'ARRAY' ) {
    local(*NULL) ;
    my $glob ;
    foreach my $glob_i ( @{$this->{TRACK_GLOBS}} ) {
      $glob = $TRACK_GLOBS_BASE . $glob_i ;
      *{$glob} = \*NULL ;
      undef *{$glob} ;
      delete *{$TRACK_GLOBS_BASE}{HASH}{$glob_i} ;
      #print "GLOBS>> $TRACK_GLOBS_BASE\::$glob_i\n" ;
    }
  }
  if ( $BLESS_TABLE->{$this->{ROOT}} && !_root_is_tracked( $this->{ROOT} ) ) {
    ##print "DEST>> $this->{ROOT}\n" ;
    foreach my $ids_i ( keys %{ $BLESS_TABLE->{$this->{ROOT}} } ) {
      delete $BLESS_TABLE->{POOL}{$ids_i} ;
    }
  }
  
  $this->unshare_vars ;
  
  $this->{DESTROIED} = 1 ;
  
  $this->unlink_pack_all(1) ;

  $this->CLEAN ;

}

#########
# CLEAN #
#########

sub CLEAN {
  my $this = shift ;
  return if ($this->{CLEANNED} || $this->{NO_CLEAN} || $NOW == $this ) ;
  
  $this->{CLEANNED} = 1 ;
  
  $this->DESTROY ;
  
  ## Too slow to unshare the variables, since you change Symbol Table.
  ## Also too slow to use Safe::World::select. Better save and reset.
  
  ############ SAVE main:: SHAREDS
    foreach my $var ( keys %{ $this->{SHARING} } ) {
      my ($var_tp,$var_name) = ( $var =~ /([\$\@\%\*])(\S+)/ ) ;
      $var_name =~ s/^{'(\S+)'}$/$1/ ;
    
      if ($var_tp eq '$') {
        my $scalar = ${$var_name} ;
        $this->{SHARING}{$var} = \$scalar ;
      }
      elsif ($var_tp eq '@') { $this->{SHARING}{$var} = [@{$var_name}] ;}
      elsif ($var_tp eq '%') { $this->{SHARING}{$var} = {%{$var_name}} ;}
      elsif ($var_tp eq '*') { $this->{SHARING}{$var} = \*{$var_name} ;}
    }
  ############
  
  my $packname = $this->{ROOT} ;
  
  foreach my $packs_i ( $this->scanpacks ) {
    $this->undef_pack($packs_i , $this->{DONOT_CLEAN} ) ;
  }

  ##$this->undef_pack("Safe::World::GLOBS::$packname") ;
  
  my $main_packname = "main::$packname\::" ;

  undef %{*{$main_packname}{HASH}} ;
  undef *{$main_packname} ;
  *{$main_packname} = *{"PACKNULL::"} ;
  delete *{'main::'}{HASH}{"$packname\::"} ;
  
  ############ RESET main:: SHAREDS
    foreach my $var ( keys %{ $this->{SHARING} } ) {
      my ($var_tp,$var_name) = ( $var =~ /([\$\@\%\*])(\S+)/ ) ;
      $var_name =~ s/^{'(\S+)'}$/$1/ ;

      if ($var_tp eq '$')    { ${$var_name} = ${ $this->{SHARING}{$var} } ;}
      elsif ($var_tp eq '@') { @{$var_name} = @{ $this->{SHARING}{$var} } ;}
      elsif ($var_tp eq '%') { %{$var_name} = %{ $this->{SHARING}{$var} } ;}
      elsif ($var_tp eq '*') { *{$var_name} = $this->{SHARING}{$var} ;}
    }
  ############
  
  return 1 ;
}

##############
# UNDEF_PACK #
##############

sub undef_pack {
  my $this = shift ;
  my ( $packname , $donot_clean ) = @_ ;

  ##print main::STDOUT "UNDEFPACK>> $packname\n" ;
  
  $packname .= '::' ;
  no strict "refs" ;
  my $package = *{$packname}{HASH} ;
  return unless defined $package ;
  
  local(*NULL) ;
  my $tmp_sub = sub{} ;
  
  no warnings ;
  local $^W = 0 ;
  
  ## 'no warning' still have some warns on Perl-5.8.x
  my $prev_sigwarn = $SIG{__WARN__} ;
  my $prev_sigdie = $SIG{__DIE__} ;
  $SIG{__WARN__} = sub{} ;
  $SIG{__DIE__} = sub{} ;
  $IGNORE_EXIT = 1 ;

  my ($fullname) ;
  foreach my $symb ( keys %$package ) {
    $fullname = "$packname$symb" ;
    if ( $symb !~ /::$/ && $symb !~ /[^\w:]/ && $symb !~ /^[1-9\.]/ && (!$donot_clean || !$donot_clean->{$symb}) ) {
      ##print main::STDOUT "undef>> $packname >> $symb\n" ;
      
      eval {
        if (defined &$fullname) {
          if (my $p = prototype $fullname) { ++$EVALX ; *{$fullname} = eval "sub ($p) {}" ;}
          else                             { *{$fullname} = $tmp_sub ;}
          undef &$fullname ;
        }

        untie *{$fullname} if tied *{$fullname} ;
        if (*{$fullname}{IO}) { close $fullname ;}
        
        #if (defined @$fullname) { undef @$fullname ;}
        if (defined *{$fullname}{ARRAY}) {
          untie @$fullname if tied @$fullname ;
          undef @$fullname ;
        }
        #undef @$fullname ;
  
        #if (defined %$fullname) { undef %$fullname ;}
        if (defined *{$fullname}{HASH}) {
          untie %$fullname if tied %$fullname ;
          undef %$fullname ;
        }
        #undef %$fullname ;
        
        #if (defined $$fullname) { undef $$fullname ;}
        untie $$fullname if tied $$fullname ;
        undef $$fullname ;
        
        undef *{$fullname} ;
      };
    }
    #else { print main::STDOUT "** $packname>> $symb >> $fullname\n" ;}
  }


  undef %{*{$packname}{HASH}} ;
  undef *{$packname} ;

  $IGNORE_EXIT = undef ;
  $SIG{__WARN__} = $prev_sigwarn ;
  $SIG{__DIE__} = $prev_sigdie ;

  return 1 ;
}

sub END {
  
  if (0)  {
    foreach my $Key ( sort {$a <=> $b} keys %{ $BLESS_TABLE->{POOL} } ) {
      my $Value = $BLESS_TABLE->{POOL}{$Key} ;
      next if !$Value ;
      my $package = *{ ref($Value) . '::' }{HASH} ;
      my $defin = %$package ? 1 : 0 ;
      print ">>> [$defin] $Key = $Value\n" ;
      
      foreach my $base ( sort keys %$BLESS_TABLE ) {
        next if $base eq 'POOL' ;
        print "    $base\n" if exists $BLESS_TABLE->{$base}{$Key} ;
      }
      
    }
  }
  
  %{ $BLESS_TABLE->{POOL} } = () ;
  $BLESS_TABLE = undef ;
  %{ $SAFEWORLDS_TABLE->{POOL} } = () ;
  $SAFEWORLDS_TABLE = undef ;
}

#######
# END #
#######

1;

__END__

=head1 NAME

Safe::World - Create multiple virtual instances of a Perl interpreter that can be assembled together.

=head1 SYNOPSIS

See I<USE> section for complexer example and the test.pl script.

  use Safe::World ;

  my $world = Safe::World->new(
  stdout => \$stdout ,     ## - redirect STDOUT to this scalar.
  stderr  => \$stderr ,    ## - redirect STDERR to this scalar.
  flush => 1 ,             ## - output is flushed, soo don't need to wait exit to
                           ##   have all the data inside $stdout.
  ) ;
  
  ## Evaluate some code:
  $world->eval(q`
     use Data::Dumper ;
     print Dumper( {a => 1 , b => 2} ) ;
  `);
  
  $world->close ; ## ensure that everything is finished and flushed.

  die($stderr) if $stderr ;
  
  print $stdout ;
  
  $world = undef ; ## Destroy the world. Here the compartment is cleanned.


B<Note that in this example, inside the World is loaded L<Data::Dumper>, but I<Data::Dumper> was loaded only inside of it, keeping the outside normal.>

=head1 DESCRIPTION

With I<Safe::World> you can create multiple virtual instances/compartments of a Perl interpreter,
that will work/run without touch the other instances/compartments and mantaining the main interpreter normal.

Actually each Each instance (WORLD object), is a Safe compartment (I<Safe::World::Compartment>) with all the
resources of a normal Perl interpreter implemented (IO, @INC, %INC, Dynaloader::, etc...). But what happens inside each World doesn't change the enverioment outside of it or other Worlds.

Each instance (WORLD object) has their own STDOUT, STDERR and STDIN handlers, also has a fake HEADOUT output (when the argument I<headout> is past) for the headers implemented inside the STDOUT.
Soo, you can use this to redirect the outputs of the WORLD object to a FILEHANDLER, SCALAR or a SUB.

The module I<Safe::World> was created for 3 purposes:

=over 10

=item 1. A Safe compartment that can be "fully" cleanned.

This enable a way to run multiple scripts in one Perl interpreter process,
saving memory and time. After each execution the Safe compartment is "fully" cleanned,
saving memory for the next compartment.

=item 2. A Safe compartment with the output handlers implemented, creating a full WORLD, working as a normal Perl Interpreter from inside.

A normal I<Safe> objects doesn't have the output handlers, actually is just a compartment to run codes that can't go outsied of it.
Having a full WORLD implemented, with the STDOUT, STDERR, STDIN and HEADERS handlers, the output can be redirected to any kind of listener.
Also the error outputs (STDERR) can be catched via I<sub> (I<CODE>), that can be displayed in the STDOUT in a nice way,
or in the case of HTML output, be displayed inside I<comment> tags, instead to go to an error log.

But to implement a full WORLD warn(), die() and exit() need to be overwrited too.
Soo you can control if exit() will really exit from the virtual interpreter, and redirect the warn messages.

=item 3. A WORLD object (a virtual Perl interpreter) that can be linked/assembled with other WORLD objects, and work/run as if the objects where only one, then be able to unlink/disassemble them.

This is the advanced purpose, that need all the previous resources, and most important thing of I<Safe::World>.
Actually this was projected to work with I<mod_perl>, soo the Perl codes can be runned in different compartments,
but can have some part of the code cached in memory, specially the Perl Modules (Classes) that need to be loaded all the time.

Soo, you can load your classes in one World, and your script/page in other World, then link them and run your code normally.
Then after run it you unlink the 2 Worlds, and only CLEAN the World with your script/page,
and now you can keep the 1st World with your Classes cached, to link it again with the next script/page to run.

Here's how to implement that:

=over 10

=item 1 Cache World.

A cache world is created, where all the classes common to the all the different scripts/pages are loaded.

=item 1 Execution World.

For each script/page is created a world, each time that is executed (unless a script need to be persistent).
Inside this worlds only the main code of the scripts/pages are loaded.

=item 1 Linking 2 WORLDS.

Using the method I<link_world()>, two worlds can be assembled. Actually one world is imported inside another.
In this case the I<Cache World> is linked to the I<Execution World>.
Now you can't evaluate codes in the I<Cache World>, since it's shared, and evaluation is only accepted in the I<Execution World>.

  my $world_cache = Safe::World->new(sharepack => ['DBI','DBD::mysql']) ;
  $world_cache->eval(" use DBI ;") ;
  $world_cache->eval(" use DBD::mysql ;") ;
  
  my ( $stdout , $stderr ) ;
  
  my $world_exec = Safe::World->new(
  stdout => \$stdout ,
  stderr => \$stderr ,
  ) ;
  
  $world_exec->link_world($world_cache) ;
  
  $world_exec->eval(q`
      $dbh = DBI->connect("DBI:mysql:database=$db;host=$host", 'user' , 'pass') ;
  `);

=back

=back

=head1 USAGE

See the I<test.pl> script for more examples.

  use Safe::World ;

  my $world = Safe::World->new(
  stdout => \$stdout ,     ## - redirect STDOUT to this scalar.
  stderr  => \$stderr ,    ## - redirect STDERR to this scalar.
  headout => \$headout ,   ## - SCALAR to hold the headers.
  autohead => 1 ,          ## - tell to handle headers automatically.
  headsplitter => 'HTML' , ## - will split the headers from the content handling
                           ##   the output as HTML.
  flush => 1 ,             ## - output is flushed, soo don't need to wait exit to
                           ##   have all the data inside $stdout.
  
  on_closeheaders => sub { ## sub to call when headers are closed (when content start).
                       my ( $world ) = @_ ;
                       my $headers = $world->headers ;

                       $headers =~ s/\r\n?/\n/gs ;
                       $headers =~ s/\n+/\n/gs ;
                       $headers .= "\015\012\015\012" ; ## add the headers end.
  
                       $world->print($headers) ; ## print the headers to STDOUT
                       $world->headers('') ; ## clean the headers scalar.
                     } ,
  
  on_exit => sub { ## sub to call when exit() happens.
               my ( $world ) = @_ ;
               $world->print("<!-- ON_EXIT_IN -->\n");
               return 0 ; ## 0 make exit() to be skiped. 1 make exit() work normal.
             } ,
  ) ;
  
  ## Evaluate some code:
  $world->eval(q`
     print "Content-type: text/html\n\n" ; 
     
     print "<html>\n" ;
     print "content1\n" ;
     
     ## print some header after print the content,
     ## but need to be before flush the output!
     $SAFEWORLD->print_header("Set-Cookie: FOO=BAR; domain=foo.com; path=/;\n") ;
     
     print "content2\n" ;
     print "</html>\n" ;
     
     warn("some alert to STDERR!") ;
     
     exit;
  `);
  
  $world->close ; ## ensure that everything is finished and flushed.
  
  print $socket $stdout ; ## print the output to some client socket.
  print $log $stderr ; ## print errors to a log.
  
  $world = undef ; ## Destroy the world. Here the compartment is cleanned.


=head1 METHODS

=head2 new

Create the World object.

B<Arguments:>

=over 10

=item root

The name of the package where the compartment will be created.

By default is used I<SAFEWORLD>B<x>, where x will increse: SAFEWORLD1, SAFEWORLD2, SAFEWORLD3...

=item stdout (GLOB|SCALAR|CODE ref)

The STDOUT target. Can be another GLOB/FILEHANDLER, a SCALAR reference, or a I<sub> reference.

DEFAULT: I<\*main::STDOUT>

=item stderr (GLOB|SCALAR|CODE ref)

The STDERR target. Can be another GLOB/FILEHANDLER, a SCALAR reference, or a I<sub> reference.

DEFAULT: I<\*main::STDERR>

=item stdin (GLOB ref)

The STDIN handler. Need to be a IO handler.

DEFAULT: I<\*main::STDIN>

=item headout (GLOB|SCALAR|CODE)

The HEADOUT target. Can be another GLOB/FILEHANDLER, a SCALAR reference, or a I<sub> reference.

=item env (HASH ref)

The HASH reference for the internal I<%ENV> of the World.

=item flush (bool)

If TRUE tell that STDOUT will be always flushed ( $| = 1 ).

I<** This is good to use if you are using a SCALAR as STDOUT. Also will run faster, since uses a simple STDOUT handler.>

=item no_clean (bool)

If TRUE tell that the compartment wont be cleaned when destroyed.

=item no_set_safeworld (bool)

If TRUE tell to not set the internal object $SAFEWORLD, that gives access to it self inside the compartment.

=item autohead (bool)

If TRUE tell that the STDOUT will handler automatically the handlers in the output, using I<headsplitter>.

=item headsplitter (REGEXP|CODE)

A REGEXP or CODE reference to split the header from the content.

Example of REGEXP:

  my $splitter = qr/(?:\r\n\r\n|\012\015\012\015|\n\n|\015\015|\r\r|\012\012)/s ; ## This is the DEFAULT

Example of SUB:

  sub splitter {
    my ( $world , $data ) = @_ ;
    
    my ($headers , $rest) = split(/\r\n?\r\n?/s , $data) ;
  
    return ($headers , $rest) ;
  }

=item sharepack (LIST)

When a World is linked to another you need to tell what packages inside it can be shared:

  my $world_cache = Safe::World->new(sharepack => ['DBI','DBD::mysql']) ;

=item on_closeheaders (CODE)

I<Sub> to be called when the headers are closed.

=item on_exit (CODE)

I<Sub> to be called when exit() is called.

I<** If the I<sub> returns '0', exit will be skiped.>

=item on_select (CODE)

I<Sub> to be called when the WORLD is selected to evaluate codes inside it.

=item on_unselect (CODE)

I<Sub> to be called when the WORLD is unselected, just after evaluate the codes.

=back

=head2 block_stdout ; block_stderr

Block the output to STDOUT/STDERR of the WORLD.

=head2 unblock_stdout ; unblock_stderr

UNblock the output to STDOUT/STDERR of the WORLD.

=head2 CLEAN

Call DESTROY() and clean the compartment.

** Do not use the World object after this!

=head2 call (SUBNAME , @ARGS)

Call a I<sub> inside the World and returning their values.

  my @ret0 = $world->call('foo::methodx', $var1 , time()); ## foo::methodx($var1 , time())
  
  my @ret1 = $world->call('methodz', 123); ## main::methodz(123)

=head2 close

Ensure that everything is finished and flushed.

B<You can't evaluate codes after this!>

=head2 close_tiestdout()

Close the tied STDOUT.

=head2 close_tiestderr()

Close the tied STDERR.

=head2 eval (CODE)

Evaluate a code inside the World and return their values.

=head2 eval_no_warn (CODE)

Evaluate a code inside the World without error alerts, warn(), die(), exit() or any output to STDERR.

=head2 eval_pack (PACKAGE , CODE)

Evaluate inside some package.

Same as:

  my $code = "print time ;" ;
  $world->eval("package foo ; $code") ;

=head2 eval_args (CODE , ARGS)

Evaluate code sending args (defining internal @_):

  $world->eval_args(' print "$_[0]\n" ' , qw(a b c) ); ## Should print 'a'.

=head2 eval_pack_args (PACKAGE , CODE , ARGS)

Same as eval_args(), but setting the package name to run the code.

=head2 flush (bool)

Set $| to 1 or 0 if I<bool> is defined.

Also flush STDOUT. Soo, if some data exists in the buffer it will be flushed to the output.

=head2 get (VAR)

Return some variable value from the World:

  my $document_root = $world->get('$ENV{DOCUMENT_ROOT}') ;

=head2 get_from (PACKAGE , VAR)

Return some variable value inside some package in the World:

  my $document_root = $world->get('Foo' , '$VERSION') ;

=head2 get_ref (VAR)

Return a reference to a variable:

  my $env = $world->get_ref('%ENV') ;
  $$env{ENV}{DOCUMENT_ROOT} = '/home/httpd/www' ; ## Set the value inside the World.

=head2 get_ref_copy (VAR)

Return reference B<copy> of a variable:

  my $env = $world->get_ref_copy('%ENV') ;

** Note that the reference inside $env is not pointing to a variable inside the World.

=head2 headers

Return the headers data.

** Note that this will only return data if I<HEADOUT> is defined as SCALAR.

=head2 use_shared (MODULE)

Load a module inside a World created for cache (an World to be linked to the others).

This will require inside the World the I<MODULE> and handle automatically the I<sharedpack> list of all the modules loaded and sub-loaded by the MODULE.

=head2 link_pack (PACKAGE)

Link some package to the world.

  $world->link_pack("Win32") ;

=head2 unlink_pack (PACKAGE)

Unlink a package.

=head2 unlink_pack_all

Unlink all the packages linked to this World.

** You shouldn't call this by your self. This is only used by DESTROY().

=head2 link_world (WORLD)

Link the compartment of a world to another.

  $world->link_world( $world_shared ) ;

=head2 unlink_world (WORLD)

Unlink/disassemble a World from another.

=head2 unlink_all_worlds

Unlink all the worlds linked to this.

=head2 op_deny (OP, ...)

Deny the listed operators from being used when compiling code in the compartment (other operators may still be permitted).

Example of use:

  $world->deny_only( qw(chroot syscall exit dump fork lock threadsv) ) ;

I<** See L<Opcode> for the OP list.>

=head2 op_deny_only (OP, ...)

Deny only the listed operators from being used when compiling code in the compartment (all other operators will be permitted).

I<** See L<Opcode> for the OP list.>

=head2 op_permit (OP, ...)

Permit the listed operators to be used when compiling code in the compartment (in addition to any operators already permitted).

I<** See L<Opcode> for the OP list.>

=head2 op_permit_only (OP, ...)

Permit only the listed operators to be used when compiling code in the compartment (no other operators are permitted).

I<** See L<Opcode> for the OP list.>

=head2 print (STRING)

Print some data to the STDOUT of the world.

=head2 print_header (STRING)

Print some data to the HEADOUT of the world.

=head2 print_stderr (STRING)

Print some data to the STDERR of the world.

=head2 print_stdout (STRING)

Same as I<print>.

Print some data to the STDOUT of the world.

=head2 redirect_stdout (SCALAR)

Redirect the STDOUT to a scalar.
Soo, you can internally redirect a peace of the output to a scalar.

In this example I want to catch what the sub I<test()> prints:

    sub test { print "sub_test[@_]" ; }
    
    print "A\n" ;
    
    my $out ;
    $SAFEWORLD->redirect_stdout(\$out) ;
    
      test(123);
    
    $SAFEWORLD->restore_stdout ;
    
    print "B\n" ;
    print "OUT: <$out>" ;

** See I<restore_stdout()>.

=head2 restore_stdout().

Restore the STDOUT output if a I<redirect_stdout()> was made before.

** See I<redirect_stdout()>.

=head2 reset

Reset the object flags. Soo, if it was closed (exited) can be reused.

You also can redefine this attributes sending this arguments:

=over 10

=item stdout (GLOB|SCALAR|CODE ref)

The STDOUT target. Can be another GLOB/FILEHANDLER, a SCALAR reference, or a I<sub> reference.

DEFAULT: I<\*main::STDOUT>

=item stderr (GLOB|SCALAR|CODE ref)

The STDERR target. Can be another GLOB/FILEHANDLER, a SCALAR reference, or a I<sub> reference.

DEFAULT: I<\*main::STDERR>

=item stdin (GLOB ref)

The STDIN handler. Need to be a IO handler.

DEFAULT: I<\*main::STDIN>

=item headout (GLOB|SCALAR|CODE)

The HEADOUT target. Can be another GLOB/FILEHANDLER, a SCALAR reference, or a I<sub> reference.

=item env (HASH ref)

The HASH reference for the internal I<%ENV> of the World.

=back

=head2 reset_internals

Reset the internal flags. Soo, if the World was exited, can be reused.

=head2 reset_output

Redefine the outputs (STDOUT, STDERR, STDIN, HEADOUT) targets.

Arguments: stdout, stderr, stdin, headout.

I<** Note that only pasted arguments will be used to redefine. Soo, wont be used default values like reset().>

I<** See reset().>

=head2 root

Return the root name of the compartment of the World.

=head2 safe

Return the I<Safe> object of the World.

=head2 scanpack_table (PACKAGE)

Scan the elements of a symbol table of a package.

=head2 scanpacks

Return the package list of a World.

=head2 select_static

Select static a World to make multiple evaluations faster:

  $world->select_static ;
    $world->eval("... 1 ...") ;
    $world->eval("... 2 ...") ;
    $world->eval("... 3 ...") ;
  $world->unselect_static ;  

=head2 unselect_static

Unselect the world. Should be called after I<select_static()>.

=head2 set (VAR , VALUE_REF) || (VAR , VALUE , 1)

Set the value of a varaible inside the World:

    my @inc = qw('.','./lib') ;
    $world->set('@INC' , \@inc) ;
    
    ## To set a value that is a reference, like an object:
    
    $world->set('$objectx' , $objecty , 1) ;    

=head2 set_sharedpack (@PACKAGE)

Set a package inside a world SHARED, soo, when this World is linked to another this package is imported.

** See argument I<sharepack> at I<new()>.

=head2 unset_sharedpack (@PACKAGE)

Unset a SHARED package.

=head2 set_vars (VARS_VALUES_LIST)

  $world->set_vars(
  '%SIG' => \%SIG ,
  '$/' => $/ ,
  '$"' => $" ,
  '$;' => $; ,
  '$$' => $$ ,
  '$^W' => 0 ,
  ) ;

=head2 share_vars (PACKAGE , VARS_LIST)

Set a list of variables to be shared:

  $world->share_vars( 'main' , [
  '@INC' , '%INC' ,
  '$@','$|','$_', '$!',
  ]) ;

=head2 unshare_vars (PACKAGE , VARS_LIST)

Unshare the shared variables. Note that this is called only to clean the package.

=head2 stdout_data (NEW_DATA)

Return the stdout data.

I<** Note that this will only return data if I<STDOUT> is defined as SCALAR.>

I<(NEW_DATA)> can be used to set the new value of stdout data or to undef it.

=head2 stdout_buffer_data (NEW_DATA)

Return the buffered stdout data.

I<** Note that this will only return data if I<STDOUT> is not FLUSHED.>

I<(NEW_DATA)> can be used to set the new value of the buffer or to undef it.

=head2 tiestdout

The tiehandler of STDOUT.

=head2 tiestderr

The tiehandler of STDERR.

=head2 warn

Send some I<warn> message to the world, that will be redirected to the STDERR of the World.

=head1 CACHING PERL MODULES EXAMPLE

To make a cache system for the Perl Modules you should use the method I<use_shared()> and 2 Worlds, one as cache and other for execution:

  use Safe::World ;
  
  ## Cache world shouldn't have output, soo using $tmp:
  my $tmp ;
  
  my $world_cache = Safe::World->new(
  stdout => \$tmp ,
  stderr  => \$tmp ,
  flush => 1 ,
  ) ;
  
  ## Cache this perl module:
  $world_cache->use_shared('Data::Dumper') ;
  
  ## Run 3 Worlds using Data::Dumper cached:
  for(1..3) {
    my ( $stdout , $stderr ) ;
    my $world = Safe::World->new(
    stdout => \$stdout ,
    stderr  => \$stderr ,
    flush => 1 ,
    ) ;
    
    $world->link_world($world_cache) ;
  
    $world->eval(q`
       print Data::Dumper::Dumper( \%INC ) ;
    `);
    
    $world->close ; ## ensure that everything is finished and flushed.
                    ## close() also make an unlink_all_worlds() to
                    ## free $world_cache for the next World. 
    
    print "$stdout\n" ;
    print "=======================\n" ;
  }


And here's the output:

  
  $VAR1 = {
            'Carp.pm' => '#shared#',
            'Exporter.pm' => '#shared#',
            'XSLoader.pm' => '#shared#',
            'strict.pm' => 'C:/Perl/lib/strict.pm',
            'warnings/register.pm' => '#shared#',
            'warnings.pm' => '#shared#',
            'overload.pm' => '#shared#',
            'Data/Dumper.pm' => '#shared#'
          };
  
  =======================
  $VAR1 = {
            'Carp.pm' => '#shared#',
            'Exporter.pm' => '#shared#',
            'XSLoader.pm' => '#shared#',
            'strict.pm' => 'C:/Perl/lib/strict.pm',
            'warnings/register.pm' => '#shared#',
            'warnings.pm' => '#shared#',
            'overload.pm' => '#shared#',
            'Data/Dumper.pm' => '#shared#'
          };
  
  =======================
  $VAR1 = {
            'Carp.pm' => '#shared#',
            'Exporter.pm' => '#shared#',
            'XSLoader.pm' => '#shared#',
            'strict.pm' => 'C:/Perl/lib/strict.pm',
            'warnings/register.pm' => '#shared#',
            'warnings.pm' => '#shared#',
            'overload.pm' => '#shared#',
            'Data/Dumper.pm' => '#shared#'
          };
  
  =======================
  

=head1 SEE ALSO

L<Safe::World::Scope>, L<HPL>, L<Safe>, L<Opcode>.

=head1 NOTES

This module was made to work with I<HPL> and I<mod_perl>,
enabling multiple executions of scripts in one Perl interpreter,
and also brings a way to cache loaded modules, making the execution of multiple
scripts and mod_perl pages faster and with less memory.

Actually this was first writed as I<HPL::PACK module>, then I haved moved it to I<Safe::World> to be shared with other projects. ;-P

** Note that was hard to implement all the enverioment inside I<Safe::World>,
soo if you have ideas or suggestions to make this work better, please send them. ;-P

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

Enjoy!

=head1 THANKS

Thanks to:

Elizabeth Mattijsen <liz@dijkmat.nl>, to test it in different Perl versions and report bugs.


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

