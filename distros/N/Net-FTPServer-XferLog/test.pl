# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use Net::FTPServer::XferLog;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

open T, 'test.xlog' or die $!;
my $hashref;


my @expected = ('FILENAME', 'NAMEFILE', 'file with spaces in it.zip', 'p1774034_11i_zhs.zip');


my $i;
while (<T>)
{
    $hashref = Net::FTPServer::XferLog->parse_line($_);
    ok($hashref->{filename}, $expected[$i++]);
    warn $hashref->{filename};
}




