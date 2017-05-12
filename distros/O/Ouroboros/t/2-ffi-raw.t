use strict;
use warnings;

use Config;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use ATHX;

if (!eval { require FFI::Raw }) {
    plan skip_all => "FFI::Raw not available";
}
elsif ($Config{nvsize} != 8) {
    plan skip_all => "unsupported NV size: $Config{nvsize}";
}
else {
    require_ok("Ouroboros");

    my @pthx = $Config{usemultiplicity} ? (FFI::Raw::ptr()) : ();

    my $svnv = FFI::Raw->new_from_ptr(Ouroboros::ouroboros_sv_nv_ptr(), FFI::Raw::double(), @pthx, FFI::Raw::ptr());
    my $val = 42 ** 0.5;
    my $arg = $val;
    my $got = $svnv->call(athx(), int \$arg);

    cmp_ok($got, "==", $val, "SvNV wrapper works");
}

done_testing;
