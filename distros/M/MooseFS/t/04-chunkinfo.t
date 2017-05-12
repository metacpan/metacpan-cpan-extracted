use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use lib '../lib';

BEGIN {
    use_ok( 'MooseFS::ChunkInfo' ) || print "Bail out!\n";
}
 
SKIP: {
    skip "no master ip", 2 unless $ENV{masterhost};
    my $mfs = MooseFS::ChunkInfo->new(
        masterhost => $ENV{masterhost},
    );
    isa_ok $mfs->info, 'HASH';
    like $mfs->loop_start, qr/^\d{10}$/;
};

done_testing;
