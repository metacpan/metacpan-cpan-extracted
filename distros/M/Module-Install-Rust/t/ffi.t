use strict;
use warnings;

use FindBin qw/$Bin/;
use Test::More;

unless (eval { require FFI::Platypus::Declare }) {
    plan(skip_all => "FFI::Platypus required for this test");
}
unless (`cargo -V`) {
    plan(skip_all => "cargo not found");
}

ok eval {
    chdir "$Bin/ffi" or die "$!";
    system "$^X -Mblib=../../blib Makefile.PL" and die "configure failed";
    system "make test" and die "build and test failed";
    system "make realclean" and die "cleanup failed";
    1;
}, "can configure and build a FFI::Platypus package";

done_testing;
