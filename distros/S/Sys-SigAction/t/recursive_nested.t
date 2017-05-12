# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl filename.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More; # tests => 5;
#BEGIN { use_ok('Sys::SigAction') };

use Sys::SigAction;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;

use Carp qw( carp cluck croak confess );
use Data::Dumper;
use Sys::SigAction qw( set_sig_handler );
use POSIX  ':signal_h' ;
use Config;
##use Sys::SigAction::Nested qw( max_depth ); #returns undef if there is no limit

#plan is a follows:
#
#  A test that sets signal handlers in nested recusive function calls.
#  The idea is that at each level of recursive call the the call frame
#  protect the signal hander in the the call above it which executes
#  after the lower one has fired. 
#
#  NOTE: this works fine on at least on arm platform... it is hoped it
#  will work fine on them all... we'll see.

my @levels = ( );
my $depth = $ARGV[0];
my $repetitions = $ARGV[1];
$repetitions = 2 if not defined $repetitions;
$depth = 10 if not defined $depth;

##my $max_depth = max_depth();
##my $arch = $Config{'archname'} ;
##print "archname = $arch\n" ;
##
#if ( $Config{'archname'} =~ m/arm/i )
##if ( defined $max_depth )
##{
##   if ( not defined $depth ) 
##   {
##      print STDERR qq(
##
##     NOTE: Bug # 105091 was filed against Sys::SigAction noting that
##     this test causes a perl segfault (apparently if the depth of
##     nested invocations is greater than 2 on an arm platform) Forcing
##     depth to $max_depth;
##
##     If this test is run manually, you can explicitly 
##     set both the depth of nesting and the number of 
##     repetitions of this test. 
##
##       perl -Ilib t/nested.t 5 2 #depth=5 repetitions=2
##
##     Because this works fine on all the other POSIX (unix) platforms
##     the smoke testers have tested on, the author suspects this is
##     a problem with the underlying signal handling in perl on ARM
##     platforms. Apparently there are no smoke testers using ARM
##     (armv5tejl excepted). So, if you want this port of perl fixed,
##     you'll want to get a stack trace from the core file resulting
##     from the segfault and file a bug against this perl port.
##
##);
##      $depth = $max_depth;
##   }
##}
##else
##{
##   $depth = 5 if not defined $depth;
##   $repetitions = 2 if not defined $repetitions;
##}

plan tests => $depth*$repetitions*2;

#recurses until $level > $depth
sub do_level
{
    my ( $level ) = @_;
    return if $level > $depth;
    my $indent = "  " x  $level;
    print $indent ."entered do_level( $level )\n" ;
    do_level( $level+1 );
    eval {
       my $ctx = set_sig_handler( SIGALRM ,sub { print $indent. "in ALRM handler at depth of $level\n"; $levels[$level-1] = $level; } ); 
       kill ALRM => $$;
    };
    if ($@) { warn "handler died at level $level: $@\n"; }
    #print $indent ."leaving do_level( $level )\n" ;
}


sub do_test
{
   my ( $p ) = ( @_ );
   my $i = 0;
   print "testing nested signal handlers to a depth of $depth\n" ;
   print "initializing \@levels array to 0 for all depths\n\n" ;
   @levels = ( 0 ) x $depth;
   for ( $i = $depth-1; $i > -1; $i-- )
   {
      ok( $levels[$i] == 0 ,"pass $p: \$levels[$i] was initialed to $levels[$i]" );
      #print "\$levels[$i] = " .$levels[$i] . "\n" ;
   }

   do_level( 1 );

   print "\n";
   $i = 0;
   for ( $i = $depth-1; $i > -1; $i-- )
   {
      ok( $levels[$i] ,"pass $p: \$levels[$i] was set by the signal handler to $levels[$i]" );
      #print "\$levels[$i] = " .$levels[$i] . "\n" ;
   }
}
my $pass = 1;
while ( $pass <= $repetitions ) {
   print "starting pass $pass\n" ;
   do_test( $pass  );
   $pass++;
} 

exit;
