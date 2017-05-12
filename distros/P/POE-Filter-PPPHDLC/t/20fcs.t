# test FCS computation and checking
use POE::Filter::PPPHDLC;
use Test::More tests => 3 + 10;

# these are private functions.  not for users

# test that it copes with a real LCP frame
my $frame =
  "\xff\x03\xc0\x21\x01\x01\x00\x18" .
  "\x02\x06\x00\x00\x00\x00\x03\x04" .
  "\xc2\x27\x05\x06\x02\x12\xbb\x8f" .
  "\x07\x02\x08\x02";
cmp_ok(POE::Filter::PPPHDLC::_pppfcs16(0xffff, $frame), '==', 0x1e2a, 'fcs computation');
$frame .= "\xd5\xe1";
cmp_ok(POE::Filter::PPPHDLC::_pppfcs16(0xffff, $frame), '==', 0xf0b8, 'fcs checking');
ok(POE::Filter::PPPHDLC::_frame_check($frame), 'frame checking');

# generate some random byte sequences and verify it against itself
for (1..10) {
  my $frame = join '', map { chr rand 256 } 1..(rand(32) + 32);
  $frame .= pack 'v', POE::Filter::PPPHDLC::_pppfcs16(0xffff, $frame) ^ 0xffff;
  ok(POE::Filter::PPPHDLC::_frame_check($frame), "trail $_");
}
