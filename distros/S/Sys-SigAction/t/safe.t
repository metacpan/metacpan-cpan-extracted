# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#lab: this could be a clone of mask.t.  The idea would be to turn on safe 
#signal handling and verify the same results.  The problem is that it does 
#not appear to work.
#

#########################

use Test::More ;
my $tests = 1;

#BEGIN { use_ok('Sys::SigAction') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;

use Carp qw( carp cluck croak confess );
use Data::Dumper;
use POSIX ':signal_h' ;
use Sys::SigAction qw( set_sig_handler sig_name sig_number );

#from mask.t:
#see commends in mask.t for concept of this test...
##summary: the kills in sigHUP are masked, and execute only after 
#sigHUP finished without interuption
my $hup = 0;
my $int = 0;
my $usr = 0;
my $cnt = 1;
sub sigHUP  {
   ok( ($cnt++ == 1) ,'sigHUP called (1)' );
   kill INT => $$;
   kill USR1 => $$;
   $hup++;
   sleep 1;
   ok( ($cnt++==2) ,'sig mask delayed INT and USR1(2)' );
}
   
sub sigINT_1 
{ 
   #since USR1 is delayed by mask of USR1 on this Signal handler
   #
   ok( ($cnt==3) ,"sigINT_1 called(3) failure: ($cnt!=3) this should have been delayed by mask until sigHUP finished" );
   $cnt++;
   $int++; 
   sleep 1;
   ok( ($cnt++==4) ,"sig mask delayed USR1 (signaled from sigHUP)(4)" );
}
sub sigUSR_1 { 
   ok( ($cnt==5) ,"sigUSR called (5) failure: ($cnt!=5) it should have been delayed by mask until sigHUP finished)" );
   $cnt++;
   $usr++; 
}


#end included functions from mask.t ... 

SKIP: { 
#   if ($] <5.008) 
#   {
#      plan skip_all => "using the safe attribute requires perl 5.8.2 or later";
#  }
   if ( ($] <5.008002) ) 
   {
      $tests += 3;
      plan tests => $tests;
      ok( 1, "NOTE: using the safe attribute requires perl 5.8.2 or later" ); 

      eval {
         local $SIG{__WARN__} = sub { die $_[0]; };
         my $h = set_sig_handler( sig_number(SIGALRM) ,sub { die "Timeout!"; }, { safe =>0 } );
      };
      #print STDERR "\ntest 2: \$\@ = '$@'\n";
      ok( $@ eq '', "safe=>0 got no warning in \$\@ = '$@'" );

      eval {
         local $SIG{__WARN__} = sub { die $_[0]; };
         my $h = set_sig_handler( sig_number(SIGALRM) ,sub { die "Timeout!"; }, { safe =>1 } );
      };
      ok( $@ ne '' ,"safe=>1 expected warning in \$\@ = '$@'" );

      eval {
         local $SIG{__WARN__} = sub { die $_[0]; };
         my $h = set_sig_handler( sig_number(SIGALRM) ,sub { die "Timeout!"; } );
      };
      ok( $@ eq "", "safe not set: no warning in \$\@ = '$@'" );
   }
   else  # ($] >= 5.008002 ) 
   {
      if ( ! $ENV{SAFE_T} ) #setting safe mode breaks masked signals
      {
         plan tests => $tests;

         print STDERR "
         
     NOTE: Setting safe=>1... with masked signals does not seem to work.
     The problem is that the masked signals are not masked when safe=>1.
     When safe=>0 they are.  

     If you have an application for safe=>1 and can come up with a patch
     for this module that gets this test working, or a patch to the test
     that shows how to fix it, please send it to me. 

     See the block below this one... which if executed would test safe mode
     with masked signals... it is a clone of part of mask.t that proves this
     is broken.

     This test can be executed from the command line as follows:

         SAFE_T=1 perl -Ilib t/safe.t

     Lincoln

     \n\n";
            
         ok( 1, "skipping test of safe flag for now" ); 
      }
      else 
      {
         #including mask.t here testing with masked signals...
         $tests = 6;
         plan tests => $tests;


         #testing again with safe on
         #set_sig_handler( 'HUP'  ,\&sigHUP   ,{ flags => SA_RESTART, mask=>[ qw( INT USR1 ) ] , safe=>1 } );
         #set_sig_handler( 'INT'  ,\&sigINT_1 ,{ flags => SA_RESTART, mask=>[ qw( USR1 )] ,safe=>1 } );
         #set_sig_handler( 'USR1' ,\&sigUSR_1 ,{ flags => SA_RESTART, safe=>1 } );
         set_sig_handler( 'HUP'  ,\&sigHUP   ,{ flags => SA_RESTART, mask=>[ qw( INT USR1 ) ] , safe=>1 } );
         set_sig_handler( 'INT'  ,\&sigINT_1 ,{ flags => SA_RESTART, mask=>[ qw( USR1 )] ,safe=>1 } );
         set_sig_handler( 'USR1' ,\&sigUSR_1 ,{ flags => SA_RESTART, safe=>1 } );
         kill HUP => $$;
         ok( ( $cnt++==6 ), "reached 6th test after first kill" );

#lab      ok( ($hup==1 ), "hup=1 ($hup)" ); 
#lab      ok( ($int==1 ), "int=1 ($int)" ); 
#lab      ok( ($usr==1 ), "usr=1 ($usr)" ); 

      }
   }
}

#ok( $int ,'sigINT called' );
#ok( $usr ,"sigUSR called $usr" );

exit;
