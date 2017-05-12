# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'


use Test::More tests => 25;
BEGIN { use_ok('Script::Toolbox', qw(:all)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

##############################################################################

unlink "/tmp/07_File.log";
$F = Script::Toolbox->new({logdir=>{mod=>'=s',mand=>1,default=>'/tmp'}});
##############################################################################
############################### TEST 2 #####################################

unlink "foo";
File( 'foo', 'baa' );
ok(!(system("grep baa foo >/dev/null 2>&1")/256)); #2

File( 'foo', 'baa' );
ok(!(system("grep baabaa foo >/dev/null 2>&1")/256)); #3

$F->File( 'foo', "\nbaa\n" );
ok(!(system("wc -l foo | grep 2 >/dev/null 2>&1")/256)); #4

$arrRef = $F->File( 'foo' );
ok( $arrRef->[0] eq "baabaa\n" && $arrRef->[1] eq "baa\n"  ); #5

unlink "foo";
$F->File( 'foo', [ "aaa\n","bbb\n","ccc\n" ] );
ok(!(system("wc -l foo | grep 3 >/dev/null 2>&1")/256)); #6
ok(!(system("grep aaa foo >/dev/null 2>&1")/256)); #7
ok(!(system("grep bbb foo >/dev/null 2>&1")/256)); #8
ok(!(system("grep ccc foo >/dev/null 2>&1")/256)); #9

unlink "foo";
$F->File( 'foo', { 1=>"aaa\n", 2=>"bbb\n", 3=>"ccc\n" } );
ok(!(system("wc -l foo | grep 3 >/dev/null 2>&1")/256)); #10
ok(!(system("grep '1:aaa' foo >/dev/null 2>&1")/256)); #11
ok(!(system("grep '2:bbb' foo >/dev/null 2>&1")/256)); #12
ok(!(system("grep '3:ccc' foo >/dev/null 2>&1")/256)); #13

unlink "foo";
$F->File( 'foo', { 1=>{ZZ=>"aaa",YY=>"xxx"}, 2=>"bbb", 3=>"ccc" } );
ok(!(system("wc -l foo | grep 8 >/dev/null 2>&1")/256)); #14
ok(!(system("grep '.VAR1 = {' 				foo >/dev/null 2>&1")/256)); #15
ok(!(system("grep '          .1. => {' 			foo >/dev/null 2>&1")/256)); #16
ok(!(system("grep '                   .YY. => .xxx.' 	foo >/dev/null 2>&1")/256)); #17
ok(!(system("grep '                   .ZZ. => .aaa.'  	foo >/dev/null 2>&1")/256)); #18
ok(!(system("grep '                 }' 			foo >/dev/null 2>&1")/256)); #19
ok(!(system("grep '          .3. => .ccc.' 		foo >/dev/null 2>&1")/256)); #20
ok(!(system("grep '          .2. => .bbb.' 		foo >/dev/null 2>&1")/256)); #21
ok(!(system("grep '        };' 				foo >/dev/null 2>&1")/256)); #22
unlink 'foo';

$f = $F->TmpFile();
print $f "Hello\n";
$r = $F->TmpFile($f);
ok( $r->[0] eq "Hello\n" ); #23

$f = $F->File("ps | grep perl |");
like( $f->[0], qr/perl/, 'Read commad output' ); #24


File("| /bin/cat >/tmp/__xx__", "Hello world." );
$f = File("/tmp/__xx__");
ok( $f->[0] eq "Hello world." ); #25
unlink "/tmp/__xx__";

unlink "/tmp/07_File.log";
