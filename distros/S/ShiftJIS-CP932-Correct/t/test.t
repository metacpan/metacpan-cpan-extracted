# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::Correct;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my($NG);
my %dbl = (
  0x8140=>0x8140, 0x82A0=>0x82A0, 0x889F=>0x889F, 0x989F=>0x989F,
  0x879C=>0x81BE, 0x879B=>0x81BF, 0xEEF9=>0x81CA, 0xFA54=>0x81CA,
  0x8797=>0x81DA, 0x8796=>0x81DB, 0x8791=>0x81DF, 0x8790=>0x81E0,
  0x8795=>0x81E3, 0x879A=>0x81E6, 0xFA5B=>0x81E6, 0x8792=>0x81E7,
);

$NG = 0;
foreach(keys %dbl){
  $NG++ if pack('n',$dbl{$_}) ne correct_cp932(pack 'n',$_);
}
print !$NG ? "ok" : "not ok", " 2\n";

print "" eq correct_cp932("") && is_corrected_cp932("") 
  ? "ok" : "not ok", " 3\n";

print "\x82\xa0\x82\xa2\x82\xa4\x81\xe0\x82\xa6\x82\xa8"
  eq correct_cp932("\x82\xa0\x82\xa2\x82\xa4\x87\x90\x82\xa6\x82\xa8")
  ? "ok" : "not ok", " 4\n";

print "\x82\xa0\x82\xa2\x82\xa4\x82\xa6\x82\xa8"
  eq correct_cp932("\x82\xa0\x82\xa2\x82\xa4\x82\xa6\x82\xa8")
  ? "ok" : "not ok", " 5\n";

print "\x8a\xbf\x8e\x9a\x81\xe7\x50\x65\x72\x6c\x81\xe0"
  eq correct_cp932("\x8a\xbf\x8e\x9a\x87\x92\x50\x65\x72\x6c\x81\xe0")
  ? "ok" : "not ok", " 6\n";

print "\x8a\xbf\x81\xbf\x50\x65\x72\x6c\x81\xe6"
  eq correct_cp932("\x8a\xbf\x87\x9b\x50\x65\x72\x6c\xfa\x5b\xfe\xff")
  ? "ok" : "not ok", " 7\n";

print "\x8a\xbf\x81\xbf\x50\x65\x72\x6c\x81\xe6"
  eq correct_cp932("\xa0\xa0\x8a\xbf\x8a\x39\x87\x9b\x50\x65\x72\x6c\xfa\x5b")
  ? "ok" : "not ok", " 8\n";
