use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use lib '../lib';

BEGIN {
    use_ok( 'MooseFS::Mounts' ) || print "Bail out!\n";
}

SKIP: {
    skip "no master ip", 3 unless $ENV{masterhost};
    my $mfs = MooseFS::Mounts->new(
        masterhost => $ENV{masterhost},
    );
    isa_ok $mfs->list, 'ARRAY', 'mounts list';
    like $mfs->list->[0]->{ip}, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, 'range as ip';
    like $mfs->list->[0]->{mount}, qr/^\/\w+/, 'mount dir path';
};

done_testing;
