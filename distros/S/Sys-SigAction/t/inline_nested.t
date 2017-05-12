# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More; # tests => 5;

use Sys::SigAction;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;

use Config;
use Carp qw( carp cluck croak confess );
use Data::Dumper;
use Sys::SigAction qw( set_sig_handler );
use POSIX  ':signal_h' ;

my $tests = 4;
my @levels = ( 0 ,0 ,0 ,0 );
sub sighandler { print "in sighandler: level 1\n" ; $levels[1] = 2; }

#plan is a follows:
#
#  A test that sets signal handlers in nested blocks, and tests that
#  at each level of nesting, the signal handler at the next level up
#  is still valid (for the same signal).  The idea is that the scope of
#  the block prevents the next level up signal handle from being overwritten.
#

SKIP: { 
   if ( ($Config{'archname'} =~ m/^arm/) and not ($ENV{'INLINE'}) )
   {
      print STDERR "

    NOTE: arm systems seem to have a defective implementation of perl POSIX
    signal handling.  This test will segfault on these platforms, if
    the block nesting is greater than 2... and I suspect if the block
    nesting itself is corrupting the call stack somehow.  This testing
    will be skipped on arm* platforms.

    All that said, this was an intentially a very twisted test.  It seems
    unlikly that one would really want to do what this tests for.  It is
    reasonable to nest signal handlers in nexted call stacks however:
    See recursive_nested.t, which does run on arm platforms.

    This test can be executed manually from the command line on arm platforms
    as follows:

       INLINE=1 perl -Ilib t/safe.t

    Lincoln\n\n" ;

      plan skip_all => "This test appears to corrupt perl's call stack on arm platforms" ;
   }
   plan tests => $tests;

   my $ctx0 = set_sig_handler( SIGALRM ,sub { print "in sighandler: level 0\n" ; $levels[0] = 1; } );

   eval {
      my $ctx1 = set_sig_handler( 'ALRM' ,'sighandler' ); 
      #print Dumper( $ctx1 );
      if ( 1 ) { 
         eval {
            my $ctx2 = set_sig_handler( SIGALRM ,sub { print "in sighandler: level 2\n"; $levels[2] = 3; } );
            eval {
               my $ctx3 = set_sig_handler( 'ALRM' ,sub {  print "in sighandler: level 3\n"; $levels[3] = 4; } );
               kill ALRM => $$;
               #undef $ctx3;
            };
            if ($@) { warn "handler died: $@\n"; }
            kill ALRM => $$;
         };
         if ( $@ ) { warn "error: $@\n"; }
      }
      kill ALRM => $$;
   };
   if ( $@ ) { warn "error: $@\n"; }


   eval {
      kill ALRM => $$;
   };
   if ($@ ) { warn "error :$@\n"; }

   my $i = 0;
   foreach my $level ( @levels )
   {
      ok( $level ,"(level $i is not 0 as expected)" );
      print "level $i = $level\n" ;
      $i++;
   }

}

exit;
