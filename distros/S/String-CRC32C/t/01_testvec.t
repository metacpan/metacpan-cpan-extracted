print "1..9\n";

use String::CRC32C 'crc32c';

print "ok 1\n";

print 0x00000000 == (crc32c "") ? "" : "not ", "ok 2\n";
print 0x22620404 == (crc32c "The quick brown fox jumps over the lazy dog") ? "" : "not ", "ok 3\n";
print 0xe3069283 == (crc32c "123456789") ? "" : "not ", "ok 4\n";
print 0xe3069283 == (crc32c "56789", crc32c "1234") ? "" : "not ", "ok 5\n";
print 0xe3069283 == (crc32c "123456789", 0) ? "" : "not ", "ok 6\n";
print 0x8a9136aa == (crc32c "\x00" x 32) ? "" : "not ", "ok 7\n";
print 0x62a8ab43 == (crc32c "\xff" x 32) ? "" : "not ", "ok 8\n";

print "ok 9\n";
