use Test::Simple tests => 125;
use Statistics::Descriptive::Weighted;
use Statistics::Descriptive;

$Tolerance = 1e-10;

ok( $weighted = Statistics::Descriptive::Weighted::Sparse->new() );
ok( $weighted->add_data( [1, 3, 5, 7],[1, 1, 1, 1] ) );

$unweighted = Statistics::Descriptive::Sparse->new();
$unweighted->add_data( [1, 3, 5, 7] );

ok( $weighted->mean() == 4, 'Sparse dataset 1 mean' );
ok( $unweighted->variance() == ( $weighted->biased_variance() * $weighted->count/ ($weighted->count - 1)), 'Sparse dataset 1 biased variance' );
ok( $weighted->max() == 7, 'Sparse dataset 1 max' );
ok( $weighted->min() == 1, 'Sparse dataset 1 min' );
ok( $weighted->weight() == 4, 'Sparse dataset 1 weight' );
ok( $weighted->count() == 4, 'Sparse dataset 1 count' );

# not explicitely specifying the weights
ok( $weighted = Statistics::Descriptive::Weighted::Sparse->new() );
ok( $weighted->add_data( [1, 3, 5, 7] ) );
ok( $weighted->mean() == 4, 'Sparse dataset 2 mean' );
ok( $unweighted->variance() == ( $weighted->biased_variance() * $weighted->count/ ($weighted->count - 1)), 'Sparse dataset 2 biased variance' );
ok( $weighted->max() == 7, 'Sparse dataset 2 max' );
ok( $weighted->min() == 1, 'Sparse dataset 2 min' );
ok( $weighted->weight() == 4, 'Sparse dataset 2 weight' );
ok( $weighted->count() == 4, 'Sparse dataset 2 count' );

ok( $stat3 = Statistics::Descriptive::Weighted::Sparse->new() );
ok( $stat3->add_data( [1, 3, 5, 7],[2, 2, 2, 2] ) ); 
ok( $stat3->mean() == $weighted->mean(), 'Sparse dataset 3 mean' );
ok( $stat3->variance() == $weighted->variance(), 'Sparse dataset 3 variance' );
ok( $stat3->max() == $weighted->max(), 'Sparse dataset 3 max' );
ok( $stat3->min() == $weighted->min(), 'Sparse dataset 3 min' );
ok( $stat3->weight() == 8, 'Sparse dataset 3 weight' );

ok( $stat3->count() == 4, 'Sparse dataset 3 count' );

ok( $stat3->weight(1) == $stat3->weight(), join ' ','Sparse dataset 3 weight of defined value' );
ok( $stat3->weight(2) == $stat3->weight(), join ' ','Sparse dataset 3 weight of undefined value' );


ok( $stat4 = Statistics::Descriptive::Weighted::Sparse->new() );
ok( $stat4->add_data( [1, 3, 5, 7],[0.1, 0.1, 0.1, 0.1] ) );
ok( $stat4->mean() == $weighted->mean(), 'Sparse dataset 4 mean' );
ok( abs($stat4->variance() - $weighted->variance()) < $Tolerance, 'Sparse dataset 4 variance' );
ok( $stat4->max() == $weighted->max(), 'Sparse dataset 4 max' );
ok( $stat4->min() == $weighted->min(), 'Sparse dataset 4 min' );
ok( $stat4->weight() == 0.4, 'Sparse dataset 4 weight' );
ok( $stat4->count() == 4, 'Sparse dataset 4 count' );

ok( $twoadd = Statistics::Descriptive::Weighted::Sparse->new() );
ok( $twoadd->add_data( [1, 3],[0.1, 0.1] ) );
ok( $twoadd->add_data( [5, 7],[0.1, 0.1] ) );
ok( $stat4->mean() == $twoadd->mean(), 'Sparse dataset 5 (two adds) mean' );
ok( abs($stat4->variance() - $twoadd->variance()) < $Tolerance, 'Sparse dataset 5 (two adds) variance' );
ok( $stat4->max() == $twoadd->max(), 'Sparse dataset 5 (two adds) max' );
ok( $stat4->min() == $twoadd->min(), 'Sparse dataset 5 (two adds) min' );
ok( $stat4->weight() == $twoadd->weight(), 'Sparse dataset 5 (two adds) weight' );
ok( $stat4->count() == $twoadd->count(), 'Sparse dataset 5 (two adds) count' );


ok( $zero = Statistics::Descriptive::Weighted::Sparse->new() );
ok( $zero->add_data( [7, 3],[0.1, 0] ) );
ok( $zero->mean() == 7, 'Sparse dataset 6 (size 1) mean' );
ok( $zero->variance() == 0, 'Sparse dataset 6 (size 1) 0 variance' );
ok( $zero->max() == 7, 'Sparse dataset 6 (size 1) max' );
ok( $zero->min() == 7, 'Sparse dataset 6 (size 1) min' );
ok( $zero->weight() == 0.1, 'Sparse dataset 6 (size 1) weight' );
ok( $zero->count() ==1, 'Sparse dataset 6 (size 1) count' );


$stat = Statistics::Descriptive::Sparse->new();
$stat->add_data(1,1,1,1,2,2,2,3,3,4);
ok( $weighted = Statistics::Descriptive::Weighted::Sparse->new() );
ok(! $weighted->add_data(1,1,1,1,2,2,2,3,3,4) );
ok(! $weighted->add_data(1,1) );
ok(! $weighted->add_data([1,1,1,1,2,2,2,3,3,4],[]) );
ok($weighted->add_data([],[]) );
ok(! $weighted->add_data([1,2,3,4],[1]) );

ok( $weighted->add_data([1,2,3,4],[4,3,2,1]) );
ok( $stat->mean() == $weighted->mean(), 'Sparse dataset 7 (counts vs weights) mean' );
#ok( $stat->variance() < $weighted->variance(), 'Sparse dataset 7 (counts vs weights) variance' );
#ok( $stat->standard_deviation() < $weighted->standard_deviation(), 'Sparse dataset 7 (counts vs weights) standard deviation' );
ok( $stat->max() == $weighted->max(), 'Sparse dataset 7 (counts vs weights) max' );
ok( $stat->min() == $weighted->min(), 'Sparse dataset 7 (counts vs weights) min' );
ok( $stat->count() > $weighted->count(), 'Sparse dataset 7 (counts vs weights) counts are different' );
ok( $stat->sample_range() == $weighted->sample_range(), 'Sparse dataset 7 (counts vs weights) sample range' );


ok( $full = Statistics::Descriptive::Weighted::Full->new() );
ok( $full->add_data( [1,2,3,4],[4,3,2,1] ) );
ok( $full->mean() == $weighted->mean(), 'Full dataset 1 (vs sparse) mean' );
ok( $full->variance() == $weighted->variance(), 'Full dataset 1 (vs sparse) variance' );
ok( $full->standard_deviation() == $weighted->standard_deviation(), 'Full dataset 1 (vs sparse) standard deviation' );
ok( $full->max() == $weighted->max(), 'Full dataset 1 (vs sparse) max' );
ok( $full->min() == $weighted->min(), 'Full dataset 1 (vs sparse) min' );
ok( $full->count() == $weighted->count(), 'Full dataset 1 (vs sparse) counts' );
ok( $full->sample_range() == $weighted->sample_range(), 'Full dataset 1 (vs sparse) range' );
ok( $full->weight() == $weighted->weight(), 'Full dataset 1 (vs sparse) weight' );
ok( $full->mode() == 1, 'Full dataset 1 mode' );

# not explicitely specifying the weights
ok( $weighted = Statistics::Descriptive::Weighted::Full->new() );
ok( $weighted->add_data( [1, 3, 5, 7] ) );
ok( $weighted->mean() == 4, 'Full dataset 2 mean' );
ok( $unweighted->variance() == ( $weighted->biased_variance() * $weighted->count/ ($weighted->count - 1)), 'Full dataset 2 biased variance' );
ok( $weighted->max() == 7, 'Full dataset 2 max' );
ok( $weighted->min() == 1, 'Full dataset 2 min' );
ok( $weighted->weight() == 4, 'Full dataset 2 weight' );
ok( $weighted->count() == 4, 'Full dataset 2 count' );

ok( $full = Statistics::Descriptive::Weighted::Full->new() );
ok( $full->add_data([-2, 7, 4, 18, -5],[1,2,1,1,1]) );
ok( $full->sum() == 29, 'Full dataset 3 - sum' );
ok( $full->quantile(0.25) == -2, 'Full dataset 3 - 0.25 quantile' );
ok( $full->quantile(0.50) == 4, 'Full dataset 3 - 0.50 quantile' );
ok( $full->median == $full->percentile(50), 'Full dataset 3 - 50% percentile equals median' );
ok( $full->quantile(0) == -5, join " ",'Full dataset 3 - quantile of 0 equals minimum' );
ok( $full->quantile(0.02) == -5, join " ",'Full dataset 3 - quantile below cdf of min variate equals minimum' );
ok( $full->add_data([7],[6]) );
ok( $full->weight(7) == 8, 'Full dataset 3 weight of a datum, after additional weight added' );
ok( $full->weight(5) == undef, join ' ','Full dataset 3 weight of undefined value' );
ok( abs($full->variance() - 40.91) < $Tolerance, join ' ','Full dataset 3 variance:',$full->variance());

ok($full->print());

ok( $full = Statistics::Descriptive::Weighted::Full->new() );
$th = [1..200];
$tho = [split '', '1' x 200];
ok( $full->add_data($th,$tho) );
ok( $full->quantile(0.99) == 198, join " ",'Full dataset 4 - 0.99 quantile' );
ok( abs($full->cdf(198) - 0.99) < $Tolerance, join " ",'Full dataset 4 - cdf of 198 is 0.99 ',$full->cdf(198) );

ok( $full->cdf(0) == 0, "Full dataset 3 - cdf of value below minimum is 0" );
ok( $full->cdf(1000) == 1, "Full dataset 3 - cdf of value above maximum is 1" );

ok( $full = Statistics::Descriptive::Weighted::Full->new() );
ok( $full->add_data([1,10],[90,10]) );
ok( $full->quantile(0.90) == 1, join " ",'Full dataset 5 - 0.9 quantile', $full->quantile(0.9) );
ok( $full->quantile(1) == 10, join " ",'Full dataset 5 - 1.0 quantile', $full->quantile(1) );
ok( $full->quantile(0.01) == 1, join " ",'Full dataset 5 - 0.01 quantile equals minimum', $full->quantile(0.01) );
ok( abs($full->cdf(1) - 0.9) < $Tolerance, join " ",'Full dataset 5 - cdf of 1 is 0.9 ',$full->cdf(1) );
ok( abs($full->cdf(2) - 0.9) < $Tolerance, join " ",'Full dataset 5 - cdf of 2 is 0.9 ',$full->cdf(2) );
ok( $full->cdf(11) == 1, join " ",'Full dataset 5 - cdf of value greater than maximum observed', $full->cdf(11) );
ok( abs($full->rtp(10) - 0.1) < $Tolerance, join " ",'Full dataset 5 - right tail prob of 10 is 0.1 ',$full->rtp(10) );
ok( $full->rtp(11) == 0, join " ",'Full dataset 5 - tail prob of value g.t. maximum ',$full->rtp(11) );
ok( abs($full->survival(2) - (1 - ($full->cdf(2) ))) < $Tolerance, join " ",'Full dataset 5 - survival function of 2 is (1 - cdf) of 2 ',$full->survival(2) );

ok( $full->survival(0) == 1, "Full dataset 5 - survival function of value below minimum is 1" );
ok( $full->survival(1000) == 0, "Full dataset 5 - survival of value above maximum is 0" );


ok( $full->rtp(0) == 1, "Full dataset 5 - rt tail prob function of value below minimum is 1" );
ok( $full->rtp(1000) == 0, "Full dataset 5 - rt tail prob of value above maximum is 0" );


## NEED TO WRITE TESTS FOR:
ok( $full = Statistics::Descriptive::Weighted::Full->new() );
ok( $full->add_data([1,3,5,7,9],[3,1,1,3,0]) );
ok( $full->median() == 4, "Full dataset 6 - median is based on linear interpolation in percentile." );
ok( abs($full->variance() - 10.1818181818) < $Tolerance, join ' ','Full dataset 6 -  variance with 0 weight variate:',$full->variance() );


ok( $full = Statistics::Descriptive::Weighted::Full->new() );
ok( $full->add_data([1]), "Full dataset 7" );
ok( $full->percentile(50), "Full dataset 7 - causes illegal division by zero in versions <= 0.4" );

## sum
## min, max, sample_range
## add range alias to sample_range
## confess on disqualified inherited functions


ok( $full = Statistics::Descriptive::Weighted::Full->new() );
ok( $full->add_data([]), "" );
