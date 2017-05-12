use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use lib '../lib';

BEGIN {
    use_ok( 'MooseFS::Server' ) || print "Bail out!\n";
}

SKIP: {
    skip "no master ip", 3 unless $ENV{masterhost};
    my $mfs = MooseFS::Server->new(
        masterhost => $ENV{masterhost},
    );
    isa_ok $mfs->info, 'HASH';
    isa_ok $mfs->list, 'ARRAY';
    like $mfs->count, qr/^\d+$/;
};

done_testing;
