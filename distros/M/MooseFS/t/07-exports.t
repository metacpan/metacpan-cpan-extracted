use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use lib '../lib';

BEGIN {
    use_ok( 'MooseFS::Exports' ) || print "Bail out!\n";
}

SKIP: {
    skip "no master ip", 3 unless $ENV{masterhost};
    my $mfs = MooseFS::Exports->new(
        masterhost => $ENV{masterhost},
    );
    isa_ok $mfs->list, 'ARRAY', 'exports list';
    like $mfs->list->[0]->{ip_range_to}, qr/^(?:\d{1,3}\.){3}\d{1,3}$/, 'range as ip';
};

done_testing;
