use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use lib '../lib';

BEGIN {
    use_ok( 'MooseFS::Info' ) || print "Bail out!\n";
}

SKIP: {
    skip "no master ip", 3 unless $ENV{masterhost};
    my $mfs = MooseFS::Info->new(
        masterhost => $ENV{masterhost},
    );
    isa_ok $mfs->info, 'HASH';
    ok $mfs->masterversion > 1400, 'inherit from Moose.pm';
    like $mfs->version, qr/^1\.\d\.\d+$/;
    like $mfs->total_space, qr/^\d+$/;
};

done_testing;
