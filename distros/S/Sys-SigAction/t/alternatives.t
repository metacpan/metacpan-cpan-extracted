# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

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

#plan is a follows:
#
#  A test that sets signal handlers using different ways of referencing the signal

my $testval = 0;

plan tests => 2;

eval 'sub sighandler { print "in subname defined sighander() sig speced as \'ALRM\'\n" ; $testval = 1; }';
$testval = 0;
eval {
   my $ctx = set_sig_handler( 'ALRM' ,'sighandler' ); 
   kill ALRM => $$;
};
if ($@) { warn "handler died: $@\n"; }
ok( $testval ,"\$testval = $testval;  was set by signal handler" );


$testval = 0;
eval {
   my $ctx = set_sig_handler( SIGALRM ,sub { print "in coderef defined signal handler signal speced as SIGALRM\n" ; $testval = 1; } );
   kill ALRM => $$;
};
if ($@) { warn "handler died: $@\n"; }
ok( $testval ,"\$testval = $testval;  was set by signal handler" );


exit;
