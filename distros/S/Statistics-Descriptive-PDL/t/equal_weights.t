use 5.010;
use strict;
use warnings;

use Test::More;

use rlib;
use lib 't/lib';

use Statistics::Descriptive::PDL::Weighted;
use Statistics::Descriptive;

use PDL::Lite;
use PDL::NiceSlice;
#use PDL::Stats;
eval 'use PDL::Stats';
if ($@) {
    plan skip_all => 'PDL::Stats not installed';
}

use Scalar::Util qw /blessed/;


my $stats_class = 'Statistics::Descriptive::PDL::Weighted';
my $tolerance = 1E-10;

test_equal_weights();

done_testing();

sub test_equal_weights {
    my $object_pdl = $stats_class->new;
    #  "well behaved" data so medians and percentiles are not interpolated
    my @data = (0..100);  
    $object_pdl->add_data(\@data, [(0.6) x scalar @data]);
    my $piddle = $object_pdl->_get_piddle;

    my @methods = qw /
        mean
        standard_deviation
        skewness
        kurtosis
        min
        max
        median
    /;

    my %method_remap = (
        mean     => 'avg',
        skewness => 'skew',
        kurtosis => 'kurt',
        standard_deviation => 'stdv',
    );

    my $test_name
      = 'Methods match between Statistics::Descriptive::PDL and '
      . 'PDL::Stats when weights are all 1';
    subtest $test_name => sub {
        foreach my $method (@methods) {
            #diag "$method\n";
            my $PDL_method = $method_remap{$method} // $method;

            #  allow for precision differences
            my $got = $object_pdl->$method;
            my $exp = $piddle->$PDL_method;
            ok (
                abs ($got - $exp) < $tolerance,
                "$method got $got, expected $exp",
            );
        }
    };

}


1;
