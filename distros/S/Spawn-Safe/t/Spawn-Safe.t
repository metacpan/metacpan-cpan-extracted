# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Spawn-Safe.t'

#########################

use Test::More tests => 20;
use Spawn::Safe;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $r;
my $app;

if ( $^O eq 'MSWin32' ) { $app = 'dir'; }
else                    { $app = '/bin/ls'; }
$r = spawn_safe( { argv => [ $app, '.' ], timeout => 100 } );
ok( $r, 'test1' );
ok( $r->{'stdout'}, 'test1 stdout' );
ok( !$r->{'stderr'}, 'test1 stderr' );
ok( !$r->{'error'}, 'test1 error' );
ok( $r->{'exit_code'} == 0, 'test1 exit code' );

$r = spawn_safe( { argv => [ '/bin/thisdoesntexist/no/no/no' ], timeout => 100 } );
ok( $r, 'test2 nonexistant' );
ok( !$r->{'stdout'}, 'test2 stdout' );
ok( !$r->{'stderr'}, 'test2 stderr' );
ok( $r->{'error'}, 'test2 error' );
ok( !$r->{'exit_code'}, 'test2 exit code' );

if ( $^O eq 'MSWin32' ) { $app = 'pause'; }
else                    { $app = '/bin/sleep'; }
$r = spawn_safe( { argv => [ $app, 20 ], timeout => 1 } );
ok( $r, 'test3 timeout' );
ok( !$r->{'stdout'}, 'test3 stdout' );
ok( !$r->{'stderr'}, 'test3 stderr' );
ok( $r->{'error'}, 'test3 error' );
ok( !$r->{'exit_code'}, 'test3 exit code' );
ok( !$r->{exit_zero}, 'test3 exit_zero' );

$r = spawn_safe( { argv => [ 'cat' ], stdin => 'a' x 16385, timeout => 10 } );
ok( $r, 'test4 pass stdin' );
ok( length( $r->{stdout} ) == 16385, 'test4 stdout length' );
ok( $r->{exit_zero}, 'test4 exit_zero' );
