package PDL::Demos::Stats;

use PDL::Graphics::Simple;

sub info {('stats', 'Statistics, linear modelling (Req.: PDL::Graphics::Simple)')}

sub init {'
use PDL::Graphics::Simple;
'}

my @demo = (
[act => q|
# This demo illustrates the PDL::Stats module,
# which lets you analyse statistical data in a number of ways.

use PDL::Stats;
$w = pgswin(); # PDL::Graphics::Simple window
srandom(5); # for reproducibility
|],

[act => q|
# First, PDL::Stats::TS - let's show three sets of random data, against
# the de-seasonalised version
$data = random(12, 3);
$data->plot_dseason( 12, { win=>$w } );
|],

[act => q|
# Now let's show the seasonal means of that data
($m, $ms) = $data->season_m( 6, { plot=>1, win=>$w } );
print "m=$m\nms=$ms";
|],

[act => q|
# Now, auto-correlation of a random sound-sample.
# See https://pdl.perl.org/advent/blog/2024/12/15/pitch-detection/ for more!
random(100)->plot_acf( 50, { win=>$w } );
|],

[act => q|
# PDL::Stats::Kmeans clusters data points into "k" (a supplied number) groups
$data = grandom(200, 2); # two rows = two dimensions
%k = $data->kmeans; # use default of 3 clusters
print "$_\t@{[$k{$_} =~ /^\n*(.*?)\n*\z/s]}\n" for sort keys %k;
$w->plot(
  (map +(with=>'points', style=>$_+1, ke=>"Cluster ".($_+1),
    $data->dice_axis(0,which($k{cluster}->slice(",$_")))->dog),
    0 .. $k{cluster}->dim(1)-1),
  (map +(with=>'circles', style=>$_+1, ke=>"Centroid ".($_+1), $k{centroid}->slice($_)->dog, 0.1),
    0 .. $k{centroid}->dim(0)-1),
  {le=>'tr'},
);
|],

[act => q|
# There's also a principal component analysis (PCA) clustering function
$data = qsort random 10, 5;      # 10 obs on 5 variables
%r = $data->pca( { plot=>1, win=>$w } );
# Here we can see that very nearly all the variance is in the first component.
|],

[act => q|
# From that PCA we can plot the original vs PCA-transformed scores
# along the first two components
$data->plot_scores( $r{eigenvector}, {win=>$w} );
|],

[act => q{
# Suppose this is a person's ratings for top 10 box office movies
# ascending sorted by box office
$y = pdl '[1 1 2 2 2 2 4 4 5 5]';
$x = cat sequence(10), sequence(10)**2; # IV with linear and quadratic component
# We do an ordinary least squares (OLS), or multiple linear regression,
# to get the underlying linear model. Here we also plot how far the real
# data was from our calculated model.
%m = $y->ols( $x, { plot=>1, win=>$w } );
print "$_\t@{[$m{$_} =~ /^\n*(.*?)\n*\z/s]}\n" for sort keys %m;
}],

[act => q{
$y = pdl '[1 1 2 2 3 3 3 3 4 5 5 5]'; # suppose this is ratings for 12 apples
$a = pdl '[1 2 3 1 2 3 1 2 3 1 2 3]'; # IV for types of apple
@b = qw( y y y y y y n n n n n n );   # IV for whether we baked the apple
# First let's look at the raw data, categorised in each independent variable:
$y->plot_stripchart( $a, \@b, { IVNM=>[qw(apple bake)], win=>$w } );
# Looks like there's a visible partition in the "bake" IV
}],

[act => q{
# Let's try the analysis of variance (ANOVA) in PDL::Stats::GLM
%m = $y->anova( $a, \@b, { IVNM=>[qw(apple bake)], plot=>0, win=>$w } );
print "$_\t@{[$m{$_} =~ /^\n*(.*?)\n*\z/s]}\n" for sort keys %m;
# The p-value of variance explained by "bake" is ~0.015 - significant
# Let's plot the means of the interaction of all IVs
$m{'| apple ~ bake | m'}->plot_means($m{'| apple ~ bake | se'},
  { IVNM=>[qw(apple bake)], plot=>1, win=>$w });
}],

[comment => q|
This concludes the demo.

Be sure to check the documentation for PDL::Stats, to see further
possibilities.
|],
);

sub demo { @demo }
sub done {'
undef $w;
'}

1;
