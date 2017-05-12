#
# Written by Travis Kent Beste
# Tue Oct 28 12:52:49 CDT 2008

use Test::More tests => 14;

# Test 1
BEGIN { use_ok('RingBuffer'); }

# Test 2:
my $buffer = [];
my $ringsize = 16;
my $obj = new RingBuffer( Buffer=>$buffer, RingSize=>$ringsize );
my $result = $obj->ring_init();
ok($result == 1, 'init');

# Test 3:
$result = $obj->ring_add(0x80);
ok($result == 1, 'added 0x80 to ring');

# Test 4:
$result = $obj->ring_add(0x05);
ok($result == 1, 'added 0x05 to ring');

# Test 5:
$result = $obj->ring_add(0xbf);
ok($result == 1, 'added 0xbf to ring');

# Test 6:
$result = $obj->ring_add(0x18);
ok($result == 1, 'added 0x18 to ring');

# Test 7:
$result = $obj->ring_add(0x00);
ok($result == 1, 'added 0x00 to ring');

# Test 8:
$result = $obj->ring_add(0xff);
ok($result == 1, 'added 0xff to ring');

# Test 9:
$result = $obj->ring_add(0xdd);
ok($result == 1, 'added 0xdd to ring');

# Test 10:
my $ch = $obj->ring_remove();
ok($ch == 0x80, 'removed 0x80 from ring');

# Test 11:
$obj->ring_add_to_front(0x80);
ok($result == 1, 'added 0x80 to ring');

# Test 12:
$ch = $obj->ring_peek();
ok($ch == 0x80, 'peek at the first item on ring');

# Test 13:
$obj->ring_clear();
ok($result == 1, 'cleared the ring');

# Test 14:
$obj->ring_print();
ok($result == 1, 'printed the ring');
