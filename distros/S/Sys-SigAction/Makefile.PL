# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use 5.005;
use ExtUtils::MakeMaker;
# add a number of tests to stop the smoke testers from reporting Failed
# in unsupported environments
#
my $arch = $Config{'archname'} ;
print "OS= $^O\narchname = $arch\n" ;

print "Checking for Microsoft Windows... (not supported)\n";
if ( $^O =~ /MSWin32/ ) {
   die qq{ 
   
   OS unsupported

   Sys::SigAction is not Supported on on $^O operating systems
   if you can make all or most of the tests work on this OS, then 
   please send patches to me, and I will consider them for a new 
   release that supports $^O.

   Note that smoke testers have had successful results in a Cygwin
   environment however.  So if you want to write scripts using
   signals on a Win32 environment consider Cygwin Bash. \n\n};
}

print "Checking for multi-threaded Perl... (warning)\n";
use Config;
eval "use threads";
#belt and suspenders....
if ( ! $@ || $Config{usethreads} || $Config{useithreads} || $Config{use5005threads} ) {
   print STDERR qq{ 
   NOTE: This perl has multithread support enabled, this is not a problem for
   single threaded perl applications.
   
   Please see "MULTITHREAD PERL" in the Sys::SigAction POD for more information.\n\n};
}

print "Checking support for signals... (required)... ";
if ( ! defined $Config{sig_name} ) {
   die q{
       Signals are not supported in this OS or perl version.
   }
}
print "OK\n" ;

#is sigaction enabled?
print "Checking support for POSIX::sigaction... (required)... ";
if ( ( $] >= 5.008 ) && 
   ! ( $Config{useposix} && $Config{d_sigaction} ) ) {
   die q{ 
   
   This perl is not supported.
   Perl must be built with 'useposix' and 'sigaction' defined.

   };
}
print "OK\n" ;


##print "Checking for armv5tejl... (not supported)\n";
###belt and suspenders....
##if ( $arch =~ m/arm/ ) {
##   warn q((
##
##   Sys::SigAction tests had problems with on armv5tejl 
##   systems.  And recently a bug was opened on for an
##   arm6 system. 
##
##   I beleive (and the smoke tester agreed) that, given
##   the fact this this module tests fine on virtually POSIX
##   OSes, that arm systems have a base perl implementation
##   of POSIX:sigaction that is likely the root cause.  
##
##   If you encounted problems on arm system please contact me
##   to discuss c
##
##   As a result of working with the filer of bug 
##   if you want to use this module anyway, or work on getting
##   it supported by fixing the perl port, you can uncomment out
##   this section of Makefile.PL to build Sys::SigAction.
##
##   If you find it works please notice me (the author). If you 
##   come up with changes that make it work... patch welcome and 
##   acknowledged.
##
##   ));
##}

print "Checking for arm platforms... " ;
if ( $archname =~ m/^arm/ ) {
   print STDERR q(
   NOTE: inline nesting of signal handlers at different bracket 
   scopes is broken on arm platforms (segfaults). See t/inline_nested.t
   for more information (this test will be skipped on this platform). 
   
   Nesting at the different call stack levels works fine, and this 
   is probably much more likely to be what would be used anyway.
);
}
else { print "OK\n" }

print "Checking for cygwin... (masking signals is broken on some versions at least)... ";
if ( $^O =~ /cygwin/ ) {
   print STDERR q(

   NOTE: Smoke testers have discovered that t/mask.t fails on at least
   some verions cygwin. Specific versions of the os and perl
   are now protected... but others may be found. On these platforms
   masking signals probably does not work. See the hash reference
   $broken_platforms for platforms known to be broken.

   If you find others, please let me (the author) know.

   );
}
else { print "OK\n" }

my $SAAD = "lib/Sys/SigAction" ;
my $SAA = "$SAAD/Alarm.pm" ;
print "Writing $SAA\n" ;
mkdir $SAAD if ( not -d $SAAD );

open( SAH, ">$SAA" );
print SAH q(
package Sys::SigAction::Alarm;
require 5.005;
use strict;
use warnings;
use vars qw( @ISA @EXPORT_OK );
require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( ssa_alarm );
my $have_hires = scalar eval 'use Time::HiRes; Time::HiRes::ualarm(0); 1;';
use POSIX qw( INT_MAX ceil ) ;
my $hrworks; 
sub ssa_alarm($)
{
   my $secs = shift;
   #print  print "secs=$secs\n";

   if ( $hrworks and ($secs le (INT_MAX()/1_000_000.0) ) )
   {
      Time::HiRes::ualarm( $secs * 1_000_000 );
   }
   else
   {
      alarm( ceil( $secs ) );
   }
}

sub hires_works { return $hrworks; }; #test support

);

print "Looking for Time::HiRes with a working ualarm()... \n" ; 
use constant HR => eval 'use Time::HiRes; Time::HiRes::ualarm(0); 1;' ;
sub forever { pause(); }
sub handler { die "TIMEDOUT"; }
my $et, $st;
my $hr_works = 0;
if ( not HR )
{
   print q(
   Time::HiRes is not installed.
   High resolution timeouts disabled.
);
}
else {
   print "Testing Time::HiRes::ualarm()...\n" ;
   $SIG{'ALRM'} = \&handler;
   eval {
      $st = Time::HiRes::time();
      eval {
         Time::HiRes::ualarm( 0.1 * 1_000_000 );
         forever();
      };
      Time::HiRes::ualarm( 0 );
      $et = Time::HiRes::time();
      #print "outside forever eval\n" ;
   };
   Time::HiRes::ualarm( 0 );
   my $delta = $et - $st;
   if ( $delta < 0.8 ) {
      print qq( 

   Time::HiRes::ualarm() exists and works.
   High resolution timeouts enabled." 
);
    $hr_works = 1;
   }
   else
   {
      warn qq(
   Time::HiRes exists on this platform but Time::HiRes::ualarm()
   appears to be broken.  High resolution timeouts disabled.
);
   }
}
print SAH '$hrworks = '."$hr_works; 1;\n" ;
close( SAH );
print "\nWrote $SAA\n" ;

if ( not $hr_works ) {
   warn qq(
   Fractional seconds in timeout_call() may be used but will be 
   raised to the next higher integer value with POSIX::ceil().
);
}

my $arm_depth = 2;
if ( $arch =~ m/arm/ ) {
   warn qq{

   Nested signal handlers only works on this platform to a depth
   of $arm_depth. See nested.t for more information.

   };
}


##my $SAN = "$SAAD/Nested.pm" ;
##print "Writing $SAN\n" ;
##
##open( SAN, ">$SAN" );
##print SAN q(
##package Sys::SigAction::Nested;
##require 5.005;
##use strict;
###use warnings;
##use vars qw( @ISA @EXPORT_OK );
##require Exporter;
##@ISA = qw( Exporter );
##@EXPORT_OK = qw( max_depth );
##my $max_depth = undef; 
##
##sub max_depth { return $max_depth; }; #test support
##
##);
##
##if ( $arch =~ m/arm/i )
##{
##   print SAN '$max_depth = 2;' ."\n\n1;" ;
##}
##else
##{
##   print SAN "1;\n" ;
##}
##close SAN;
##

#ok... enough defensiveness... 
my $args = {
    'NAME'		=> 'Sys::SigAction',
    'VERSION_FROM'	=> 'lib/Sys/SigAction.pm', # finds $VERSION
    'MIN_PERL_VERSION'	=> 5.6.0,
    'PREREQ_PM'		=> {
       'Test::More'  =>  0
       ,POSIX => 0 
    }, 
    'ABSTRACT_FROM' => 'lib/Sys/SigAction.pm', # retrieve abstract from module
    'AUTHOR'     => 'Lincoln A. Baxter <lab-at-lincolnbaxter-dot-com>',
    'clean'      => { FILES => "lib/Sys/SigAction/"  },
    'META_MERGE'  => {
          "meta-spec" => { version => 2 },
          resources => {
          repository => {
                type => 'git',
                git => 'git://github.com/labaxter/sys-sigaction.git',
                web => 'https://github.com/labaxter/sys-sigaction'
            },
          },
        }

};

print "MakeMaker version = $ExtUtils::MakeMaker::VERSION\n";
if ($ExtUtils::MakeMaker::VERSION >= 6.3002 ) {
   $args->{LICENSE} = 'perl';
}

WriteMakefile( %$args );

