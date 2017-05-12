#############################################################################
## Name:        PLJava.pm
## Purpose:     PLJava
## Author:      Graciliano M. P.
## Modified by:
## Created:     04/07/2004
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package PLJava ;


############

sub SV_eval { SV( eval("package main ; $_[0]") ) ;}

############
      
use 5.006 ;

#use strict qw(vars);
#use vars qw($VERSION @ISA) ;

$VERSION = '0.04' ;

########
# BOOT # The boot will be made by PLJava.c
########

# use DynaLoader ;
# @ISA = qw(DynaLoader) ;
# bootstrap PLJava $VERSION ;

###########
# REQUIRE # can't require, since Perl can run without a library when embeded.
###########

  #use Data::Dumper ;

BEGIN {
  my ($path) = ( $INC{'PLJava.pm'} =~ /^(.*?)[\w\.]+$/ );
  $path =~ s/[\\\/:]+$// ;
  
  my $lib = "$path/lib" ;
  unshift (@INC, $lib) if -d $lib ;
}

########
# VARS #
########

  #use vars qw($SVCODE) ;

  my $SV_CLEAN_X = 100 ;

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
      delete $SVTBL{$Key} if !defined $SVTBL{$Key} ;
    }
  }

  if (ref $_[0]) {
    ++$SVCNT ;
    $SVTBL{$SVCNT} = $_[0] ;
    weaken( $SVTBL{$SVCNT} ) ;
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

PLJava - This project will embed Perl into Java.

=head1 USAGE

  import perl5.Perl ;
  import perl5.SV ;
  
  public class test {
  
    public static void main(String argv[]) {
       
       Perl.eval("print qq`Hello World!\n` ;") ;
       
       ///////////////////
       
       SV foo = Perl.NEW("foo") ; // $foo = new foo() ;
       
       foo.call("subtest") ;  // $foo->subtest() ;
       
       ///////////////////
       
       String s = Perl.eval(" 'time: ' + time() ") ;
       
       int i = Perl.eval_int(" 2**10 ") ; // 1024

       int n = Perl.eval_int(" 10/3 ") ; // 3
       int d = Perl.eval_double(" 10/3 ") ; // 3.33333333333333
       
       ///////////////////
       
       SV array = Perl.eval_sv("  [ 'a' , 'b' , 'c' ]  ") ;
       
       String e0 = array.elem(0) ; // a
       String e1 = array.elem(1) ; // b
       String e2 = array.elem(2) ; // c
       
       ///////////////////
       
       SV hash = Perl.eval_sv("  { a => 11 , b => 22 , c => 33 }  ") ;
       
       String k_a = hash.key("a") ; // 11
       String k_b = hash.key("b") ; // 22
       String k_c = hash.key("c") ; // 33

     }
  
  }

=head1 PREREQUISITES

=over 4

=item JAVA SDK 1.4+

Home & Download:

http://java.sun.com/

=item Perl 5.6+

Home:

http://www.perl.com/

Download from:

http://www.activestate.com/Products/Download/Download.plex?id=ActivePerl

http://www.activestate.com/Solutions/Programmer/Perl.plex

=back

=head1 BUILD/INSTALL

First install the Java and Perl binaries.

Don't forget to set the enverioment variables for Java. Examples:

  JAVA_BIN=C:\j2sdk1.4.0\bin
  JAVA_HOME=C:\j2sdk1.4.0
  JAVA_INCLUDE=C:\j2sdk1.4.0\include

You also will need to have the Java and Perl binaries in the search PATH:

  PATH=C:\j2sdk1.4.0\bin;C:\Perl\bin\;%PATH%

After have the binaries well installed just type:

  Perl MakeFile.PL
  nmake

Now you are able to run the test.java example:

  nmake test
  ## or:
  java test

I<Note that after build PLJava you will have a I<./built> directory with all the
files needed to be with your Java application. In this directory you also will
have the test.java example to test it in this directory.>

Enjoy!

=head1 Java package: perl5

All the compiled Java classed will be inside the I<perl5> package/directory.

To use PLJava from your Java application you will need this files in the main
diretory of your application:

  PLJava.dll     ## The PLJava library that loads the Perl interpreter.
  PLJava.pm      ## Perl side of PLJava.
  Perl56.dll     ## The Perl library in case that you have Perl built dynamic.
  perl5/*        ## Diretory with PLJava classes.
  lib/*          ## A Perl lib directory with basic .pm files (strict, warnings, etc...)

I<Take a look in the ./built directory after build PLJava.>

=head1 SWIG

The source files generated by SWIG (I<PLJava.java, PLJava_wrap.c, PLJavaJNI.java>)
come already built for your convenience. If you want to install SWIG to generate this files again
just type:

  nmake swig

Home:

http://www.swig.org/

Download from:

http://prdownloads.sourceforge.net/swig/swigwin-1.3.21.zip

I<** Don't forget to add SWIG in the search PATH:>

  PATH=C:\SWIG-1.3.21;%PATH%

=head1 Win32

You will need to have VC++ 6 to compile PLJava, since your Perl version for Win32 (from ActiveState)
will be probably compiled with VC++, and we need the same compiler of the interpreter
to embed a Perl program.

=head1 Linux

I haven't tested it on Linux yet, but should work!

=head1 Threads

The support to call Perl from Java from multiple Java Threads was added and tested on Win32, where Threads are native.

Note that if you are compiling PLJava with Perl 5.8+ you can use Perl Threads too.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


