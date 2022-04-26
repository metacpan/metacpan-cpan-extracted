use 5.010;
use strict;
use warnings;

use Test::More;

use rlib;
use lib 't/lib';


use Statistics::Descriptive::PDL;
use Statistics::Descriptive::PDL::SampleWeighted;


use Scalar::Util qw /blessed/;


my $stats_class     = 'Statistics::Descriptive::PDL';
#my $stats_class_wtd = 'Statistics::Descriptive::PDL';
my $stats_class_wtd = 'Statistics::Descriptive::PDL::SampleWeighted';
my $tolerance = 1E-10;

#use Devel::Symdump;
#my $obj = Devel::Symdump->rnew(__PACKAGE__); 
#my @xsubs = sort grep {$_ =~ /pdl/i} $obj->functions();
#print join "\n", @xsubs;

test_small_samples();
test_wikipedia_percentile_example();
test_equal_weights();
test_percentile_from_hash();
test_geometric_mean_large_sample();

done_testing();

sub test_small_samples {
    my $weighted   = $stats_class_wtd->new;
    $weighted->add_data({15 => 1, 12 => 1});

    is $weighted->skewness, undef, 'skew undefined when two samples';
    $weighted->add_data({1 => 1});
    ok defined $weighted->skewness, 'skew defined when three samples';

    is $weighted->kurtosis, undef, 'kurtosis undefined when three samples';
    $weighted->add_data({2 => 1});
    ok defined $weighted->kurtosis, 'kurtosis defined when four samples';
}


sub test_percentile_from_hash {
    
    my @data = (15, 20, 35, 40, 50);
    my @wts  = (1) x @data;
    my %data_hash;
    @data_hash{@data} = @wts;
    my $weighted   = $stats_class_wtd->new;
    $weighted->add_data(\%data_hash);

    is $weighted->percentile(40),   29, 'interpolated pctl 40, weighted';
    is $weighted->percentile(50), $weighted->median, 'median same as 50th percentile';

    $weighted->add_data(\@data, \@wts);
    is $weighted->percentile(40), 29,                  'interpolated pctl 75, weighted, after doubling data' . join ' ', @data;
    is $weighted->percentile(50), $weighted->median,   "median same as 50th percentile, " . join ' ', @data;

    ok $weighted->values_are_unique, "unique flag set to true value after calculating percentiles";

    #  data from R
    my %exp = (
        20 => 19, 30 => 20, 40 => 29,
        50 => 35, 60 => 37, 70 => 40,
        80 => 42, 90 => 50,
        21 => 19.45,
    );

    for my $p (sort {$a <=> $b} keys %exp) {
        cmp_ok abs ($weighted->percentile($p) - $exp{$p}),
                '<',
                1e-10,
                "interpolated pctl $p, weighted, doubled data";
    }
    
}

sub test_wikipedia_percentile_example {
    my @data = (15, 20, 35, 40, 50);
    my @wts  = (1) x @data;
    my $unweighted = $stats_class->new;
    my $weighted   = $stats_class_wtd->new;
    $unweighted->add_data(\@data);
    $weighted->add_data(\@data, \@wts);

    is $unweighted->percentile(40), 29, 'interpolated pctl 40, unweighted';
    is $weighted->percentile(40),   29, 'interpolated pctl 40, weighted';
    is $weighted->percentile(50), $weighted->median, 'median same as 50th percentile';
    is $weighted->percentile(50), $unweighted->median, 'weighted and unweighted median';

    $weighted->add_data(\@data, \@wts);
    $unweighted->add_data(\@data);
    is $weighted->percentile(40), 29,                  'interpolated pctl 75, weighted, after doubling data' . join ' ', @data;
    is $weighted->percentile(50), $weighted->median,   "median same as 50th percentile, " . join ' ', @data;
    is $weighted->percentile(50), $unweighted->median, 'weighted and unweighted median';

    ok $weighted->values_are_unique, "unique flag set to true value after calculating percentiles";

    #  data from R
    my %exp = (
        20 => 19, 30 => 20, 40 => 29,
        50 => 35, 60 => 37, 70 => 40,
        80 => 42, 90 => 50,
        21 => 19.45,
    );

    for my $p (sort {$a <=> $b} keys %exp) {
        cmp_ok abs($unweighted->percentile($p) - $exp{$p}),
                '<',
                1e-10,
                "interpolated pctl $p, unweighted, doubled data";
        cmp_ok abs ($weighted->percentile($p) - $exp{$p}),
                '<',
                1e-10,
                "interpolated pctl $p, weighted, doubled data";
    
        #diag $p . ' ' . $weighted->percentile($p);
    }

#diag $weighted->median;
#diag $weighted->_get_weights_piddle;
#diag $weighted->_get_piddle;
#diag $unweighted->_get_piddle;
#diag $unweighted->median;

    @data = (1..4);
    $unweighted = $stats_class->new;
    $weighted   = $stats_class_wtd->new;
    $unweighted->add_data(\@data);
    $weighted->add_data(\@data, [(1) x scalar @data]);

    is ($unweighted->percentile(75), 3.25, 'interpolated pctl 75 of 1..4, unweighted');
    is ($weighted->percentile(75),   3.25, 'interpolated pctl 75 of 1..4, weighted');
    
    is $weighted->percentile(50), $weighted->median, 'median same as 50th percentile';

    @data = (15, 20, 25, 30, 35, 40);
    $unweighted = $stats_class->new;
    $weighted   = $stats_class_wtd->new;
    $unweighted->add_data(\@data);
    $weighted->add_data(\@data, [(1) x scalar @data]);

    is ($unweighted->percentile(75), 33.75, 'interpolated pctl 75, unweighted');
    is ($weighted->percentile(75),   33.75, 'interpolated pctl 75, weighted');
    is $weighted->percentile(50), 27.5, '50th percentile';
    is $weighted->percentile(50), $weighted->median, 'median same as 50th percentile';

    is $weighted->iqr, 12.5, 'iqr as expected (1)';
    is $weighted->iqr, $weighted->percentile(75) - $weighted->percentile(25), 'iqr as expected (2)';

}

sub test_equal_weights {
    my $unweighted = $stats_class->new;
    my $weighted   = $stats_class_wtd->new;
    #  "well behaved" data so median is not interpolated
    my @data = (1..100);
    $unweighted->add_data(\@data);
    $weighted->add_data(\@data, [(1) x scalar @data]);

    my @methods = qw /
        mean
        standard_deviation
        skewness
        kurtosis
        min
        max
        median
        percentile
    /;

    my %method_remap = (
        #mean     => 'avg',
        #skewness => 'skew',
        #kurtosis => 'kurt',
        #standard_deviation => 'standard_deviation',
        #median     => 'median_interpolated',
        #percentile => 'percentile_interpolated',
    );
    my %method_args = (
        percentile => [91.5],
        #median     => [50],
    );

    my $test_name
      = "Methods match between $stats_class and "
      . "$stats_class_wtd when weights are all 1, "
      . "and using interpolation for percentiles";
    subtest $test_name => sub {
        foreach my $method (@methods) {
            #diag "$method\n";
            my $wtd_method = $method_remap{$method} // $method;
            my $args_to_pass = $method_args{$method};

            #  allow for precision differences
            my $got = $weighted->$wtd_method (@$args_to_pass);
            my $exp = $unweighted->$method (@$args_to_pass);

            ok (
                abs ($got - $exp) < $tolerance,
                "$method got $got, expected $exp",
            );
        }
    };

}

sub test_geometric_mean_large_sample {
    my $unweighted = $stats_class->new;
    my $weighted   = $stats_class_wtd->new;
    #  "well behaved" data so median is not interpolated
    my @data = (1..1000);
    $unweighted->add_data([@data, @data]);
    $weighted->add_data(\@data, [(2) x scalar @data]);

    my $gm_u = $unweighted->geometric_mean;
    my $gm_w = $weighted->geometric_mean;

    ok abs ($gm_w - $gm_u) < $tolerance,
       "geometric mean for large sample should not be Inf";

}




1;
