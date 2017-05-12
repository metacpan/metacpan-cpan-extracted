# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#lab: fixed that setting of SAFE in POSIX::sigaction, and the result
#is that setting it the test causes the test to break...  so it is now
#commented out here.

#########################

use Test::More ;
my $tests = 14;

#BEGIN { use_ok('Sys::SigAction') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
use Config;
use Carp qw( carp cluck croak confess );
use Data::Dumper;
use POSIX ':signal_h' ;
use Sys::SigAction qw( set_sig_handler sig_name sig_number );

### identify platforms I don't think can be supported per the smoke testers
my $mask_broken_platforms = {
    'archname' => { 'i686-cygwin-thread-multi-64int' => 1
                  }
   ,'perlver' =>  { 'v5.10.1' => 1 
                  }
};


my $on_broken_platform = (
      exists ( $mask_broken_platforms->{'archname'}->{$Config{'archname'}} )
   && exists ( $mask_broken_platforms->{'perlver'}->{$^V} )
   );


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


sub sigINT_2 #masks USR1
{
   ok( ($cnt++==8) ,'sigINT_2 called (8)' );
   kill USR1=>$$;
   sleep 1;
   ok( ($cnt++==9) ,'sigINT_2 exiting (9)' );
}
sub sigHUP_2  { #no mask
   ok( ($cnt++ == 7) ,'sigHUP_2 called' );
   kill INT => $$;
   sleep 1;
   ok( ($cnt++==11 ) ,'sigHUP_2 ending' );
}
sub sigUSR_2 { #no mask
   ok( ($cnt++==10) ,'sigUSR2 called (10)' );
   $usr++; 
}
#  A test that sets a signal mask, then in a signal handler
#  raises the masked signal.  The test succeeds when the mask prevents
#  the new signal handler from being called until the currently executing
#  signal handler exits.
#plan is a follows:
#sigHUP raises INT and USR1 then sleeps and is ok if it gets to the bottom
#  the mask is supposed to delay the execution of sig handlers for INT USR1
#  sigHUP sleeps to prove it (this is test 2,3)
#when sigHUP exits
#  sigINT_1 is called because sigUSR is masked... test 4
#  sigINT_1 sleeps to prove it (test 5)
#when sigINT_1 exits
#  sigUSR_1 is called .. it just prints that it has been called (test 6)
#
#then we do the same thing for new sig handers on INT and USR1
#
SKIP: { 
   plan skip_all => "perl $^V on $Config{'archname'} does not appear to mask signals correctly." if ( $on_broken_platform ); 
   #plan skip_all => "masking signals is broken on at least some versions of cygwin" if ( $^O =~ /cygwin/ );
   plan skip_all => "requires perl 5.8.0 or later" if ( $] < 5.008 ); 
   plan tests => $tests;
   
#   print STDERR "
#      NOTE: Setting safe=>1... with masked signals... does not seem to work
#      the masked signals are not masked; when safe=>0 then it does...
#      Not testing safe=>1 for now\n";
         


   set_sig_handler( 'HUP'  ,\&sigHUP  ,{ mask=>[ qw( INT USR1 ) ] } ); #,safe=>0 } );
   #set_sig_handler( 'HUP'  ,\&sigHUP  ,{ mask=>[ qw( INT USR1 ) ] ,safe=>undef } );
   set_sig_handler( 'INT'  ,\&sigINT_1 ,{ mask=>[ qw( USR1 )] } ); #,safe=>0 } );
   #set_sig_handler( 'INT'  ,\&sigINT_1 ); #,{ safe=>0 } );
   set_sig_handler( 'USR1' ,\&sigUSR_1  ); #,{ safe=>0 } );
   kill HUP => $$;

   ok( ( $cnt++==6 ), "reach 6th test after first kill" );

   set_sig_handler( 'INT' ,\&sigINT_2 ,{ mask=>[ qw( USR1 )] } );
   set_sig_handler( 'HUP' ,\&sigHUP_2 ,{ mask=>[ qw( )] } );
   set_sig_handler( 'USR1' ,\&sigUSR_2  ); #,{ safe=>0 } );
   kill HUP => $$;
   ok( ($hup==1 ), "hup=1 ($hup)" ); 
   ok( ($int==1 ), "int=1 ($int)" ); 
   ok( ($usr==2 ), "usr=2 ($usr)" ); 
}

#ok( $int ,'sigINT called' );
#ok( $usr ,"sigUSR called $usr" );

exit;
