#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 77;
BEGIN { use_ok 'Statistics::RankCorrelation' }

my @x = qw( 0 0 0 0 );
my @y = @x;
my @x_rank = qw( 2.5 2.5 2.5 2.5 ); 
my @y_rank = @x_rank;
my %x_ties = ( 0 => [ 0, 1, 2, 3 ] );
my %y_ties = %x_ties;
my( $r, $t ) = ( 1, 1 );

my $c = eval { Statistics::RankCorrelation->new };
isa_ok $c, 'Statistics::RankCorrelation', 'An empty object';

$c = eval { Statistics::RankCorrelation->new( \@x, \@x ) };
isa_ok $c, 'Statistics::RankCorrelation';
is_deeply $c->x_data, \@x, 'x data';
is_deeply $c->y_data, \@y, 'y data zero padded';
is_deeply $c->x_rank, \@x_rank, 'x rank';
is_deeply $c->y_rank, \@y_rank, 'y rank';
is_deeply $c->x_ties, \%x_ties, 'x ties';
is_deeply $c->y_ties, \%y_ties, 'y ties';
is $c->spearman, $r, 'spearman rho';  # This and Kendall are undef in R.
is $c->csim, $t, 'csim';

@x = @x_rank = qw( 1 2 3 4 );
@y = qw( 0.1 0.2 0.3 0.4 );
@y_rank = @x_rank;
$c = eval { Statistics::RankCorrelation->new(\@x, \@y) };
isa_ok $c, 'Statistics::RankCorrelation';
is_deeply $c->x_data, \@x, 'x data';
is_deeply $c->y_data, \@y, 'y data';
is_deeply $c->x_rank, \@x_rank, 'x rank';
is_deeply $c->y_rank, \@y_rank, 'y rank';
ok !keys(%{$c->x_ties}), 'x not tied';
ok !keys(%{$c->y_ties}), 'y not tied';
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';
is $c->csim, 1, 'csim';

@x = qw( 1 2 3 4 5 6 7 8 );
@y = qw( 8 7 6 5 4 3 2 1 );
$c = Statistics::RankCorrelation->new(\@x, \@y);
ok !keys(%{$c->x_ties}), 'x not tied';
ok !keys(%{$c->y_ties}), 'y not tied';
( $r, $t ) = ( -1, -1 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';
is $c->csim, 0.125, 'csim';

# http://faculty.vassar.edu/lowry/ch3b.html
@x = qw( 1 2 3 4 5 6 7 8 );
@y = qw( 2 1 5 3 4 7 8 6 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
ok !keys(%{$c->x_ties}), 'x not tied';
ok !keys(%{$c->y_ties}), 'y not tied';
( $r, $t ) = ( 0.833, 0.643 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';

# tied ranks
@x = qw( 1   3   2   4   5   6   );
@y = qw( 1.0 3.2 2.1 3.2 3.2 4.3 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
ok !keys(%{$c->x_ties}), 'x not tied';
ok scalar(keys(%{$c->y_ties})), 'y ties';
#( $r, $t ) = ( 0.941, 0.745 );
( $r, $t ) = ( 0.941, 0.894 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';

# http://fonsg3.let.uva.nl/Service/Statistics/RankCorrelation_coefficient.html
@x = qw( 579 509 527 516 592 503 511 517 538 );
@y = qw( 594 513 566 588 584 510 535 514 582 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
ok !keys(%{$c->x_ties}), 'x not tied';
ok !keys(%{$c->y_ties}), 'y not tied';
( $r, $t ) = ( 0.767, 0.667 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';

# http://www.cohort.com/costatnonparametric.html
@x = qw( 8.7  8.5  9.4 10   6.3  7.8  11.9 6.5  6.6  10.6 10.2 7.2  8.6  11.1 11.6 );
@y = qw( 5.95 5.65 6   5.7  4.7  5.53 6.4  4.18 6.15 5.93  5.7 5.68 6.13  6.3  6.03 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
ok !keys(%{$c->x_ties}), 'x not tied';
ok scalar(keys(%{$c->y_ties})), 'y ties';
( $r, $t ) = ( 0.649, 0.498 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';

# http://en.wikipedia.org/wiki/Spearman%27s_rank_correlation_coefficient
@x = qw( 106 86 100 100 99 103 97 113 113 110 );
@y = qw(   7  0  28  50 28  28 20  12   7  17 );
my @sx = qw( 86 97 99 100 100 103 106 110 113 113 );
my @sy = qw(  0 20 28  28  50  28   7  17   7  12 );
@x_rank = qw( 1 2 3 4.5  4.5 6 7   8 9.5 9.5 ); 
@y_rank = qw( 1 6 8 8   10   8 2.5 5 2.5 4   );
$c = Statistics::RankCorrelation->new( \@x, \@y, sorted => 1 );
is_deeply $c->x_data, \@sx, 'x sorted data';
is_deeply $c->y_data, \@sy, 'y sorted by x data';
is_deeply $c->x_rank, \@x_rank, 'x rank';
is_deeply $c->y_rank, \@y_rank, 'y rank';
ok scalar(keys(%{$c->x_ties})), 'x ties';
ok scalar(keys(%{$c->y_ties})), 'y ties';
( $r, $t ) = ( -0.214, -0.167 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';

# http://en.wikipedia.org/wiki/Kendall's_tau
@x = qw( 1 2 3 4 5 6 7 8 );
@y = qw( 3 4 1 2 5 7 8 6 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
ok !keys(%{$c->x_ties}), 'x not tied';
ok !keys(%{$c->y_ties}), 'y not tied';
( $r, $t ) = ( 0.738, 0.571 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';

# http://www2.warwick.ac.uk/fac/sci/moac/currentstudents/peter_cock/python/rank_correlations/
@x = qw( 5.05 6.75 3.21 2.66 );
@y = qw( 1.65 26.5 -5.93 7.96 );
@x_rank = qw( 3 4 2 1 ); 
@y_rank = qw( 2 4 1 3 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
is_deeply $c->x_rank, \@x_rank, 'x rank';
is_deeply $c->y_rank, \@y_rank, 'y rank';
ok !keys(%{$c->x_ties}), 'x not tied';
ok !keys(%{$c->y_ties}), 'y not tied';
( $r, $t ) = ( 0.4, 0.333 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';

@y = qw( 1.65 2.64 2.64 6.95 );
@y_rank = qw( 1 2.5 2.5 4 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
is_deeply $c->y_rank, \@y_rank, 'y rank';
ok !keys(%{$c->x_ties}), 'x not tied';
ok scalar(keys(%{$c->y_ties})), 'y ties';
( $r, $t ) = ( -0.632, -0.548 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';

# http://www.biostat.wustl.edu/archives/html/s-news/2002-01/msg00065.html
@x = qw( 0  0  0  0 20 20  0 60  0 20 10 10  0 40  0 20  0  0  0  0 );
@y = qw( 0 80 80 80 10 33 60  0 67 27 25 80 80 80 80 80 80  0 10 45 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
ok scalar(keys(%{$c->x_ties})), 'x ties';
ok scalar(keys(%{$c->y_ties})), 'y ties';
( $r, $t ) = ( -0.186, -0.159 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';

# R
@x = qw( 44.4 45.9 41.9 53.3 44.7 44.1 50.7 45.2 60.1 );
@y = qw(  2.6  3.1  2.5  5.0  3.6  4.0  5.2  2.8  3.8 );
# [ 3, 6, 1, 8, 4, 2, 7, 5, 9 ]
$c = Statistics::RankCorrelation->new( \@x, \@y );
ok !keys(%{$c->x_ties}), 'x not tied';
ok !keys(%{$c->y_ties}), 'y not tied';
( $r, $t ) = ( 0.6, 0.444 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';

# http://www.statsdirect.com/help/nonparametric_methods/kend.htm
@x = qw( 4 10 3 1  9 2 6 7 8 5 );
@y = qw( 5  8 6 2 10 3 9 4 7 1 );
$c = Statistics::RankCorrelation->new( \@x, \@y );
ok !keys(%{$c->x_ties}), 'x not tied';
ok !keys(%{$c->y_ties}), 'y not tied';
( $r, $t ) = ( 0.685, 0.511 );
ok $r == sprintf( '%.3f', $c->spearman ), 'spearman rho';
ok $t == sprintf( '%.3f', $c->kendall ), 'kendall tau';
