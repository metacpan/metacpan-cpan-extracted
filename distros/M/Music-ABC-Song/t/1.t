# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
use Music::ABC::Song ;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $number = 1 ;
my $archivename = "some_archive.abc" ;
#my $o = Music::ABC::Song->new(number=>$number, archivename=>$archivename) ;
my $o = Music::ABC::Song->new(number=>$number, archivename=>$archivename) ;

ok($o, "Object creation") ;
ok($o->number() == $number, "Song number") ;
ok($o->archivename() == $archivename, "Archive name") ;

ok($o->header("B", "booknametest"), "Setting scalar header") ;
ok($o->header("B") eq "booknametest", "Scalar Header") ;

$o->header("T", "title1") ;
$o->header("T", "title2") ;

ok($o->header("T")->[0] eq "title1", "First title") ;
ok($o->header("T")->[1] eq "title2", "Second title") ;

