use strict;
use warnings;

use Config;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use ATHX;

my %NVSIZE_TYPE = (
    8 => "double",
    16 => "longdouble",
);

if (!eval { require FFI::Platypus }) {
    plan skip_all => "FFI::Platypus not available";
}
elsif ($Config{nvsize} == 16 && $FFI::Platypus::VERSION < 0.41 && !eval { require Math::LongDouble }) {
    # See https://github.com/plicease/FFI-Platypus/pull/63
    plan skip_all => "FFI::Platypus >= 0.41 required";
}
elsif (!defined $NVSIZE_TYPE{$Config{nvsize}}) {
    plan skip_all => "unsupported NV size: $Config{nvsize}";
}
else {
    require_ok("Ouroboros");

    my $ffi = FFI::Platypus->new();
    my @pthx = $Config{usemultiplicity} ? ("opaque") : ();

    my $nvtype = $NVSIZE_TYPE{$Config{nvsize}};
    my $svnv = $ffi->function(Ouroboros::ouroboros_sv_nv_ptr(), [ @pthx, "opaque" ], $nvtype);
    my $val = 42 ** 0.5;
    my $arg = $val;
    my $got = $svnv->call(athx(), int \$arg);

    cmp_ok($got, "==", $val, "SvNV wrapper works");
}

done_testing;
