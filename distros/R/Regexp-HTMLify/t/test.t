# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/test.t'

#########################

use strict;
use warnings;

use Test;
BEGIN { plan tests => 5, todo => [] };
use Regexp::HTMLify;
1 && ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

2 && ok(HTMLifyGetColormapCSS() ne '');

my @qr;
$_ = qr(_QR_COMPILE_TEST_);
if (m#(.*)_QR_COMPILE_TEST_(.*)#) {
  @qr = ($1,$2);
}
3 && ok(scalar @qr == 2);

4 && ok(HTMLifyRE(qr((.))) eq qq[$qr[0]<span class="cDef0">(<span class="cDef14" >.</span>)</span>$qr[1]]);

$_ = 'test';
$_ =~ m#(test)#;
5 && ok(HTMLifyREmatches($_) eq q[<span class="cDef14" >test</span>]);
