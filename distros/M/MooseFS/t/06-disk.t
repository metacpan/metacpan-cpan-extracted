use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    use_ok( 'MooseFS::Disk' ) || print "Bail out!\n";
}
 
SKIP: {
    skip "no master ip", 1 unless $ENV{masterhost};
    my $mfs = MooseFS::Disk->new(
        masterhost => $ENV{masterhost},
    );
    isa_ok $mfs->info, 'HASH';
};

done_testing;
