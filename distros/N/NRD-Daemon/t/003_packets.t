
use strict;
use warnings;

use Test::More;
use NRD::Packet;

plan tests => 9;

my $packet = NRD::Packet->new();
my $temp_file = "/tmp/nsca2_test.tmp";
my $message = 'message';
open TEMP, ">", $temp_file or die $!;

print TEMP $packet->pack($message);
print TEMP $packet->pack($message x 2);
print TEMP $packet->pack($message x 100);
print TEMP $packet->pack('a' x 1024); #1K
print TEMP $packet->pack('b' x (1024*256)); #256K
print TEMP $packet->pack("\n\t");
print TEMP $packet->pack(chr(234).chr(196));
print TEMP $packet->pack(chr(400));

close TEMP;

open TEMP2, "<", $temp_file or die "$!";

cmp_ok($packet->unpack(*TEMP2), 'eq', 'message', 'message');
cmp_ok($packet->unpack(*TEMP2), 'eq', 'message' x 2, 'message x 2');
cmp_ok($packet->unpack(*TEMP2), 'eq', 'message' x 100, 'message x 100');

cmp_ok($packet->unpack(*TEMP2), 'eq', 'a' x 1024, '1K transported correctly');
cmp_ok($packet->unpack(*TEMP2), 'eq', 'b' x (1024*256), '256KB transported correctly');

cmp_ok($packet->unpack(*TEMP2), 'eq', "\n\t", 'return and tab transported correctly');

cmp_ok($packet->unpack(*TEMP2), 'eq', chr(234).chr(196), 'special chars');
#cmp_ok($packet->unpack(*TEMP2), 'eq', chr(400), 'utf8 chars transported correctly');

close TEMP2;
#unlink $temp_file or die $!;
#

TODO: {
   local $TODO = 'Tryout freezing and unfreezing 1MB Packets';
   # 1MB Packets should throw exceptions
   fail('Freeze a bigger than max_size packet');
   fail('Unfreeze a bigger than max_size packet');
}
