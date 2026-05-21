use strict;
use warnings;
use Test::More tests => 6;
use File::Spec;

use PDF::FacturX::Embed qw(find_icc_profile);

# 1. Auto-détection : sur dev (gs installé) on trouve un ICC
my $icc = find_icc_profile();
ok(defined $icc,           'find_icc_profile returns a path');
ok(-r $icc,                "ICC file readable: $icc");
ok((-s $icc) > 0,          'ICC file non-empty');
like($icc, qr/\.icc?$|sRGB|rgb/i, 'looks like an ICC profile path');

# 2. Repli : un sRGB.icc DOIT exister dans share/icc/ (embarqué dans la dist)
my $here = __FILE__;
my @parts = File::Spec->splitpath($here);
my $bundled = File::Spec->catfile($parts[1], '..', 'share', 'icc', 'sRGB.icc');
ok(-r $bundled, "bundled ICC fallback exists: $bundled");
my $size = -s $bundled;
ok($size > 1000, "bundled ICC size reasonable ($size bytes)");

