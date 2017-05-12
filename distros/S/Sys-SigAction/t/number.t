# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 4;
BEGIN { use_ok('Sys::SigAction') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;

use POSIX ':signal_h' ;
use Sys::SigAction qw( sig_name sig_number );

ok( sig_number( 'INT' ) == SIGINT ,'INT => SIGINT' );
ok( sig_number( 'KILL' ) == SIGKILL ,'KILL => SIGKILL' );
ok( sig_number( 'HUP' ) == SIGHUP ,'HUP => SIGHUP' );

exit;
