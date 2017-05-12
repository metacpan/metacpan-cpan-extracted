# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..25\n";}
END {print "not ok 1\n" unless $loaded;}

use Config;
use RIPEMD160;
use RIPEMD160::MAC;

$loaded = 1;
print "ok 1  (use RIPEMD160;)\n";

######################### End of black magic.

if ($Config{'byteorder'} ne '1234') {
    print "The byte-order isn't '1234', so the following tests will fail\n";
}

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package RIPEMD160Test;

# 2: Constructor

print (($ripemd160 = new RIPEMD160) ? "" : "not ", "ok 2  (new)\n");

# 3: Basic test data as defined in RFC 1321

%data = ("" 
	 =>
	 "9c1185a5c5e9fc54612808977ee8f548b2258d31",
	 
	 "a"
	 =>
	 "0bdc9d2d256b3ee9daae347be6f4dc835a467ffe",
	 
	 "abc"
	 =>
	 "8eb208f7e05d987a9b044a8e98c6b087f15a0bfc",
	 
	 "message digest"
	 =>
	 "5d0689ef49d2fae572b881b123a85ffa21595f36",
	 
	 "abcdefghijklmnopqrstuvwxyz"
	 =>
	 "f71c27109c692c1b56bbdceb5b9d2865b3708dbc",
	 
	 "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
	 =>
	 "12a053384a9c0c88e405a06c27dcf49ada62eb2b",
	 );

$failed = 0;
foreach (sort(keys(%data)))
{
    $ripemd160->reset;
    $ripemd160->add($_);
    $digest = $ripemd160->digest;
    $hex = unpack("H*", $digest);
    if ($hex ne $data{$_})
    {
	$failed++;
    }
}
print ($failed ? "not " : "", "ok 3  (std-test-vectors)\n");

# 4: "A...Za...z0...9"
{
    $ripemd160->reset;
    $ripemd160->add("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
    $ripemd160->add("abcdefghijklmnopqrstuvwxyz");
    $ripemd160->add("01234");
    $ripemd160->add("56789");
    $digest = $ripemd160->digest;
    $hex = unpack("H*", $digest);
    if ($hex ne "b0e20b6e3116640286ed3a87a5713079b21f5189") {
	print "not ";
    }
    print "ok 4  (A...Za...z0...9)\n";
}

# 5: adding 8 times "1234567890"
{
    my ($i);
    $ripemd160->reset;
    for ($i=0; $i<8; $i++) {
	$ripemd160->add("12345");
	$ripemd160->add("67890");
    }
    $digest = $ripemd160->digest;
    $hex = unpack("H*", $digest);
    if ($hex ne "9b752e45573d4b39f4dbd3323cab82bf63326bfb") {
	print "$hex: not ";
    }
    print "ok 5  (8 x \"1234567890\")\n";
}

# 6: adding 1 million times a single "a"
{
    my ($million_a) = "a" x 1000000;
    $ripemd160->reset;
## Extreme slow version: 
#    for ($i=0; $i< 1000000; $i++) {
#	$ripemd160->add("a");
#    }
#
    $ripemd160->add($million_a);
    $digest = $ripemd160->digest;
    $hex = unpack("H*", $digest);
    if ($hex ne "52783243c1697bdbe16d37f97f68f08325dc1528") {
	print "$hex: not ";
    }
    print "ok 6  (1e6 x \"a\")\n";
}


# 7: Various flavours of file-handle to addfile

open(F, "<$0");

$ripemd160->reset;
$ripemd160->addfile(F);
$hex = $ripemd160->hexdigest;
print ($hex ne '' ? "" : "not ");
print ("ok 7  (Various flavours of file-handle to addfile)\n");

$orig = $hex;

# 8: Fully qualified with ' operator

seek(F, 0, 0);
$ripemd160->reset;
$ripemd160->addfile(RIPEMD160Test'F);
$hex = $ripemd160->hexdigest;
print ($hex ne '' ? "" : "not ");
print ("ok 8  (Fully qualified with \' operator)\n");

# 9: Fully qualified with :: operator

seek(F, 0, 0);
$ripemd160->reset;
$ripemd160->addfile(RIPEMD160Test::F);
$hex = $ripemd160->hexdigest;
print ($hex ne '' ? "" : "not ");
print ("ok 9  (Fully qualified with :: operator)\n");

# 10: Type glob

seek(F, 0, 0);
$ripemd160->reset;
$ripemd160->addfile(*F);
$hex = $ripemd160->hexdigest;
print ($hex ne '' ? "" : "not ");
print ("ok 10 (Type glob)\n");

# 11: Type glob reference (the prefered mechanism)

seek(F, 0, 0);
$ripemd160->reset;
$ripemd160->addfile(\*F);
$hex = $ripemd160->hexdigest;
print ($hex ne '' ? "" : "not ");
print ("ok 11 (Type glob reference (the prefered mechanism))\n");

# 12: File-handle passed by name (really the same as 9)

seek(F, 0, 0);
$ripemd160->reset;
$ripemd160->addfile("RIPEMD160Test::F");
$hex = $ripemd160->hexdigest;
print ($hex ne '' ? "" : "not ");
print ("ok 12 (File-handle passed by name (really the same as 9))\n");

# 13: Other ways of reading the data -- line at a time

seek(F, 0, 0);
$ripemd160->reset;
while (<F>)
{
    $ripemd160->add($_);
}
$hex = $ripemd160->hexdigest;
print ($hex ne '' ? "" : "not ");
print ("ok 13 (Other ways of reading the data -- line at a time)\n");

# 14: Input lines as a list to add()

seek(F, 0, 0);
$ripemd160->reset;
$ripemd160->add(<F>);
$hex = $ripemd160->hexdigest;
print ($hex ne '' ? "" : "not ");
print ("ok 14 (Input lines as a list to add())\n");

# 15: Random chunks up to 128 bytes

seek(F, 0, 0);
$ripemd160->reset;
while (read(F, $hexata, (rand % 128) + 1))
{
    $ripemd160->add($hexata);
}
$hex = $ripemd160->hexdigest;
print ($hex ne '' ? "" : "not ");
print ("ok 15 (Random chunks up to 128 bytes)\n");

# 16: All the data at once

seek(F, 0, 0);
$ripemd160->reset;
undef $/;
$data = <F>;
$hex = $ripemd160->hexhash($data);
print ($hex ne '' ? "" : "not ");
print ("ok 16 (All the data at once)\n");
close(F);

# 17: Using static member function

$hex = RIPEMD160->hexhash($data);
print ($hex ne '' ? "" : "not ");
print ("ok 17 (Using static member function)\n");

package RIPEMD160MACTest;

sub test {
    my($nummer, $digest, $key, @data) = @_;

    my($mac) = new RIPEMD160::MAC($key);
    $mac->add(@data);
    print "not " if ($mac->hexmac() ne $digest);
    print "ok $nummer (RIPEMD160::MAC std-test-vector from RFC2286)\n";
}
    
test(18,
     "24cb4bd6 7d20fc1a 5d2ed773 2dcc3937 7f0a5668", 
     chr(0x0b) x 20, 
     "Hi There");
    
test(19,
     "dda6c021 3a485a9e 24f47420 64a7f033 b43c4069", 
     "Jefe",
     "what do ya want for nothing?");

test(20,
     "b0b10536 0de75996 0ab4f352 98e116e2 95d8e7c1", 
     chr(0xaa) x 20,
     chr(0xdd) x 50);

test(21,
     "d5ca862f 4d21d5e6 10e18b4c f1beb97a 4365ecf4", 
     chr(0x01).chr(0x02).chr(0x03).chr(0x04).chr(0x05).
     chr(0x06).chr(0x07).chr(0x08).chr(0x09).chr(0x0a).
     chr(0x0b).chr(0x0c).chr(0x0d).chr(0x0e).chr(0x0f).
     chr(0x10).chr(0x11).chr(0x12).chr(0x13).chr(0x14).
     chr(0x15).chr(0x16).chr(0x17).chr(0x18).chr(0x19),
     chr(0xcd) x 50);

test(22,
     "76196939 78f91d90 539ae786 500ff3d8 e0518e39", 
     chr(0x0c) x 20,
     "Test With Truncation");

test(23,
     "6466ca07 ac5eac29 e1bd523e 5ada7605 b791fd8b", 
     chr(0xaa) x 80,
     "Test Using Larger Than Block-Size Key - Hash Key First");

test(24,
     "69ea6079 8d71616c ce5fd087 1e23754c d75d5a0a", 
     chr(0xaa) x 80,
     "Test Using Larger Than Block-Size Key and Larger Than One Block-Size Data");

test(25,
     "69ea6079 8d71616c ce5fd087 1e23754c d75d5a0a", 
     chr(0xaa) x 80,
     "Test Using Lar", 
     "ger Than Block-Size K",
     "ey and Larger Than One Block-Size Dat",
     "a");
