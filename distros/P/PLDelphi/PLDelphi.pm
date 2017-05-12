#############################################################################
## Name:        PLDelphi.pm
## Purpose:     PLDelphi
## Author:      Graciliano M. P.
## Modified by:
## Created:     04/07/2004
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package PLDelphi ;

use vars qw($SVCODE $CALLRET) ;

############

sub SV_eval { $CALLRET = SV( eval("package main ; $SVCODE") ) ;}
sub STR_eval { $CALLRET = eval("package main ; $SVCODE") . '' ;}

############
      
use 5.006 ;

use strict qw(vars);
use vars qw($VERSION @ISA) ;

$VERSION = '0.02' ;

########
# BOOT # The boot will be made by PLDelphi.c
########

# use DynaLoader ;
# @ISA = qw(DynaLoader) ;
# bootstrap PLDelphi $VERSION ;

###########
# REQUIRE # can't require, since Perl can run without a library when embeded.
###########

  #use Data::Dumper ;

BEGIN {
  my ($path) = ( $INC{'PLDelphi.pm'} =~ /^(.*?)[\w\.]+$/ );
  $path =~ s/[\\\/:]+$// ;
  
  my $lib = "$path/lib" ;
  unshift (@INC, $lib) if -d $lib ;
  
  $|=1;
}

########
# VARS #
########

  my $SV_CLEAN_X = 3 ;

  my (%SVTBL , $SVCNT , $SVCLS) ;

##############
# DUMP_SVTBL #
##############

sub dump_SVTBL {
  require Data::Dumper ;
  print Data::Dumper::Dumper(\%SVTBL) ;
}

######
# SV #
######

sub SV {
  if ($#_ > 0) { return SV([@_]) ;}
  
  if ( ++$SVCLS >= $SV_CLEAN_X ) {
    $SVCLS = 0 ;
    foreach my $Key ( keys %SVTBL ) {
      #print "sv[$Key]> $SVTBL{$Key}\n" ;
      delete $SVTBL{$Key} if !defined $SVTBL{$Key} ;
    }
    #dump_SVTBL() ;
  }

  if (ref $_[0]) {
    ++$SVCNT ;
    $SVTBL{$SVCNT} = $_[0] ;
    ##weaken( $SVTBL{$SVCNT} ) ;    
    #print "SV> $SVCNT\n" ;
    return $SVCNT ;
  }
  else {
    my $ref = $_[0] ;
    return SV( \$ref ) ;
  }
}

##########
# GET_SV #
##########

sub get_SV {
  my $id = shift ;
  if ( !defined $SVTBL{$id} ) { return ;}
  return $SVTBL{$id} ;
}

##########
# SV_VAL #
##########

sub SV_val {
  my $id = shift ;
  if ( !defined $SVTBL{$id} ) { return ;}
  
  if    ( ref $SVTBL{$id} eq 'SCALAR' ) { return "${$SVTBL{$id}}" ;}
  elsif ( ref $SVTBL{$id} eq 'ARRAY' )  { return join ' ' , @{$SVTBL{$id}} ;}
  else                                  { return "$SVTBL{$id}" ;}
}

###########
# SV_TYPE #
###########

sub SV_type {
  my $id = shift ;
  if ( !defined $SVTBL{$id} ) { return ;}
  return ref $SVTBL{$id} ;
}

###########
# SV_ELEM #
###########

sub SV_elem {
  my $id = shift ;
  if ( !defined $SVTBL{$id} ) { return ;}
  return eval { $SVTBL{$id}[ $_[0] ] } ;
}

###########
# SV_SIZE #
###########

sub SV_size {
  my $id = shift ;
  if ( !defined $SVTBL{$id} ) { return ;}
  return eval { $#{ $SVTBL{$id} } + 1 } ;
}

##########
# SV_KEY #
##########

sub SV_key {
  my $id = shift ;
  if ( !defined $SVTBL{$id} ) { return ;}
  return eval { $SVTBL{$id}{ $_[0] } } ;
}

##########
# SV_GET #
##########

sub SV_get {
  my $id = shift ;
  if ( !defined $SVTBL{$id} ) { return ;}
  my $ref =  $SVTBL{$id} ;
  return eval("\$ref->$_[0]") ;
}

##########
# SV_SET #
##########

sub SV_set {
  my $id = shift ;
  if ( !defined $SVTBL{$id} ) { return ;}
  my $ref =  $SVTBL{$id} ;
  return eval("\$ref->$_[0] = \$_[1]") ;
}

###########
# SV_CALL #
###########

sub SV_call {
  my $id = shift ;
  my $method = shift ;
  if ( !defined $SVTBL{$id} || !ref($SVTBL{$id}) || !is_SvBlessed($SVTBL{$id}) ) { return ;}
  return $SVTBL{$id}->$method(@_) ;
}

###########
# SV_DUMP #
###########

sub SV_dump {
  my $id = shift ;
  if ( !defined $SVTBL{$id} ) { return ;}
  require Data::Dumper ;
  return Data::Dumper::Dumper($SVTBL{$id}) ;
}

##############
# SV_DESTROY #
##############

sub SV_destroy {
  my $id = shift ;
  delete $SVTBL{$id} ;
  return ;
}

#######
# END #
#######

1;

__END__



=head1 NAME

PLDelphi - This project will embed Perl into Delphi.

=head1 USAGE

  program ConsoleTest;
  
  {$APPTYPE CONSOLE}
  
  uses
    SysUtils,
    PLDelphi_dll ;
  
  var
    browser , response : SV ;
      
  begin
  
    Perl.use('WWW::Mechanize');
  
    browser := Perl.NEW('WWW::Mechanize');
  
    response := browser.call_sv('get',' "http://www.perl.com/" ') ;
  
    writeln( response.call('content') ) ;
    
    FreeAndNil(response) ;
    FreeAndNil(browser) ;
  
  end.


=head1 PREREQUISITES

=over 4

=item DELPHI 6+

Home:

http://www.borland.com/

=item Perl 5.6+

Home:

http://www.perl.com/

Download from:

http://www.activestate.com/Products/Download/Download.plex?id=ActivePerl

http://www.activestate.com/Solutions/Programmer/Perl.plex

=back

=head1 BUILD/INSTALL

First install Delphi and Perl binaries.

You also will need to have Perl binaries in the search PATH:

  PATH=C:\Perl\bin\;%PATH%

After have the binaries well installed just type:

  Perl MakeFile.PL
  nmake

Then you should compile the ConsoleTest test project in Delphi (ConsoleTest.dpr).
After this you are able to run the B<ConsoleTest.exe> example.

I<Note that after build PLDelphi you will have a I<./built> directory with all the
files needed to be with your Delphi application. In this directory you also will
have the I<ConsoleTest.exe> example to test it in this directory.>

I<Note that maybe you will need to copy by hand Perl56.dll to the I<./built> directory
to have full standalone version of PLDelphi (without the need to install Perl).>

Enjoy!

=head1 Delphi package:

To use PLDelphi from your Delphi application without need to install Perl you
will need this files in the main diretory of your application:

  PLDelphi.dll     ## The PLDelphi library that loads the Perl interpreter.
  PLDelphi.pm      ## Perl side of PLDelphi.
  Perl56.dll       ## The Perl library in case that you have Perl built dynamic.
  PLDelphi_dll.pas ## PLDelphi classes and DLL wrapper.
  lib/*            ## A Perl lib directory with basic .pm files (strict, warnings, etc...)

I<Take a look in the ./built directory after build PLDelphi.>

=head1 Win32

You will need to have VC++ 6 to compile PLDelphi, since your Perl version for Win32 (from ActiveState)
will be probably compiled with VC++, and we need the same compiler of the interpreter
to embed a Perl program.

=head1 Linux

I haven't ported it to Linux yet. Help welcome!

=head1 Threads

Note that if you are compiling PLDelphi with Perl 5.8+ you can use Perl Threads too.

=head1 SEE ALSO

L<PLJava>, L<LibZip>, L<PAR>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


