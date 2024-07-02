use strict;
use warnings;

use Test::More;

use rlib;
use lib 't/lib';
use Scalar::Util qw /blessed/;

use Statistics::Descriptive::PDL;
use Statistics::Descriptive::PDL::Weighted;
use Statistics::Descriptive::PDL::SampleWeighted;

my @classes = qw /
    Statistics::Descriptive::PDL
    Statistics::Descriptive::PDL::Weighted
    Statistics::Descriptive::PDL::SampleWeighted
/;

my @data = (1..10);
my @weights;
foreach my $class (@classes) {
    my $obj = $class->new;
    if ($class =~ /Weighted/) {
        @weights = (1) x @data;
        $obj->add_data (\@data, \@weights);
    }
    else {
        $obj->add_data (\@data);
    }
    my @available_stats = $obj->available_stats;
    foreach my $stat (@available_stats) {
        my @args;
        if ($stat =~ /percentile/) {
            @args = (5);
        }
        my $result = $obj->$stat (@args);
        ok !blessed ($result), "Result for $stat is a simple scalar, $class";
    }
}

done_testing();
