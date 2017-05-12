# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'


use Test::More tests => 11;
BEGIN { use_ok('Script::Toolbox') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

##############################################################################

unlink "/tmp/08_Dir.log";
$F = Script::Toolbox->new({logdir=>{mod=>'=s',mand=>1,default=>'/tmp'}});
##############################################################################
############################### TEST 2 #####################################

system( 'mkdir -p /tmp/__TeSt__; cd /tmp/__TeSt__; touch x y z xyz' );
$d = $F->Dir("/tmp/__TeSt__");
ok( $d->[0] eq 'x'  );#2 
ok( $d->[1] eq 'xyz');#3
ok( $d->[2] eq 'y' ); #4
ok( $d->[3] eq 'z' ); #5

$d = $F->Dir('/tmp/__TeSt__', '!x');
ok( $d->[0] eq 'y' ); #6
ok( $d->[1] eq 'z' ); #7

$d = $F->Dir("/tmp/__TeSt__", 'x');
ok( $d->[0] eq 'x' ); #8
ok( $d->[1] eq 'xyz');#9

$d = $F->Dir("/tmp/__TeSt__", '^y');
ok( $d->[0] eq 'y' ); #10
ok( $#{$d} == 0 );    #11


system( "rm -rf  /tmp/__TeSt__" );
unlink "/tmp/08_Dir.log";
