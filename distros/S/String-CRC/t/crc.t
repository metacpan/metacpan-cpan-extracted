#!/usr/local/bin/perl5.004 -I./blib/arch -I./blib/lib

print "1..9\n";

require String::CRC;

$v1 = String::CRC::crc("This is the test string", 16);
print ($v1 == 28315 ? "ok 1\n" : "not ok 1\n");

$v1 = String::CRC::crc("This is the test string", 32);
print ($v1 == 3441983474 ? "ok 2\n" : "not ok 2\n");

($v1, $v2) = String::CRC::crc("This is the test string", 48);
print ($v1 == 59726 ? "ok 3\n" : "not ok 3\n");
print ($v2 == 3041122264 ? "ok 4\n" : "not ok 4\n");

($v1, $v2) = String::CRC::crc("This is the test string", 64);
print ($v1 == 2781376167 ? "ok 5\n" : "not ok 5\n");
print ($v2 == 3489868687 ? "ok 6\n" : "not ok 6\n");


$v1 = String::CRC::crc("This is the test string");
print ($v1 == 3441983474 ? "ok 7\n" : "not ok 7\n");


$pv = String::CRC::crc("This is the test string", 64);
($v1, $v2) = unpack("LL", $pv);
print ($v1 == 2781376167 ? "ok 8\n" : "not ok 8\n");
print ($v2 == 3489868687 ? "ok 9\n" : "not ok 9\n");

