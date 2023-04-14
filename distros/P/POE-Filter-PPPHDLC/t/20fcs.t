# test FCS computation and checking
use strict;
use warnings;

use POE::Filter::PPPHDLC;
use Test::More tests => 5 + 10;

# these are private functions.  not for users

# test that it copes with a real LCP frame
{
  my $frame =
    "\xff\x03\xc0\x21\x01\x01\x00\x18" .
    "\x02\x06\x00\x00\x00\x00\x03\x04" .
    "\xc2\x27\x05\x06\x02\x12\xbb\x8f" .
    "\x07\x02\x08\x02";
  cmp_ok(POE::Filter::PPPHDLC::_pppfcs16(0xffff, $frame), '==', 0x1e2a, 'fcs computation');
  $frame .= "\xd5\xe1";
  cmp_ok(POE::Filter::PPPHDLC::_pppfcs16(0xffff, $frame), '==', 0xf0b8, 'fcs checking');
  ok(POE::Filter::PPPHDLC::_frame_check($frame), 'frame checking');
}

# Regression test for https://rt.cpan.org/Public/Bug/Display.html?id=141718
# The frame contains a \n and a /s was missed on a regex.
{
  my $frame141718 =
    "\x9C\xF9\\\xC0\x15[\xAE\x8A" .
    "\r_\xC1\xA1\x1B\xAC~\x9D" .
    "\xFF\x17F\xC1\xFA\xA5B_" .
    "^\xCF\xDBB\xE3\xF0\xB7\xBD" .
    "\x84[\xF7\x01>\xBC\xBC\xBD" .
    "\"p\n\xB3";
  cmp_ok(POE::Filter::PPPHDLC::_pppfcs16(0xffff, $frame141718), '==', 0xf0b8, 'regression test for RT#141718');
  ok(POE::Filter::PPPHDLC::_frame_check($frame141718), 'frame checking');
}

# generate some random byte sequences and verify it against itself
for (1..10) {
  my $frame = join '', map { chr rand 256 } 1..(rand(32) + 32);
  $frame .= pack 'v', POE::Filter::PPPHDLC::_pppfcs16(0xffff, $frame) ^ 0xffff;
  ok(POE::Filter::PPPHDLC::_frame_check($frame), "trial $_") or do {
    diag(unpack("H*", $frame));
  }
}
