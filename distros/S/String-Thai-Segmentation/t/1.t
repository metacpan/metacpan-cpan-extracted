# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use String::Thai::Segmentation;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$sg=String::Thai::Segmentation->new();
@data=$sg->cut("ไก่จิกเด็กตายบนปากโอ่ง	Suicide is painless.	โปรดลงโทษฉัน	วันนี้ฉันทำเธอร้องไห้");

if (scalar @data == 35) {
	ok(2);
}