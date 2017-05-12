use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'MooseFS::CheckInfo' ) || print "Bail out!\n";
}

SKIP: {
    skip "no master ip", 2 unless $ENV{masterhost};
    my $mfs = MooseFS::CheckInfo->new(
        masterhost => $ENV{masterhost},
    );
    isa_ok $mfs->info, 'HASH';
    like $mfs->check_loop_start_time, qr/^\d{10}$/;
};

done_testing;
