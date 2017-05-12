use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use lib '../lib';

BEGIN {
    use_ok( 'MooseFS::Matrix' ) || print "Bail out!\n";
}


SKIP: {
    skip "no master ip", 4 unless $ENV{masterhost};
    my $mfs = MooseFS::Matrix->new(
        masterhost => $ENV{masterhost},
    );
    isa_ok $mfs->info, 'ARRAY';
    is $#{$mfs->info}, 10, 'matrix has 11 rows';
    isa_ok $mfs->goal2, 'HASH';
    like $mfs->goal2->{valid2}, qr/^\d+$/;
};

done_testing;
