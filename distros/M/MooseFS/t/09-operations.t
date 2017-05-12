use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use lib '../lib';

BEGIN {
    use_ok( 'MooseFS::Operations' ) || print "Bail out!\n";
}

SKIP: {
    skip "no master ip", 3 unless $ENV{masterhost};
    my $mfs = MooseFS::Operations->new(
        masterhost => $ENV{masterhost},
    );
    isa_ok $mfs->list, 'ARRAY', 'mounts list';
    like $mfs->list->[0]->{ip}, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, 'range as ip';
    like $mfs->list->[0]->{info}, qr/^\/\w+/, 'mount dir path';
    ok $mfs->list->[0]->{stats_lasthour}->{statfs} > 0, 'statfs ops';
};

done_testing;
