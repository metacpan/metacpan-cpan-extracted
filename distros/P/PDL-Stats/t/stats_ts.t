use strict;
use warnings;
use Test::More;
use PDL::LiteF;
use PDL::Stats::TS;
use Test::PDL;

{
  my $a = sequence 10;
  is_pdl $a->acvf(4), pdl('82.5 57.75 34 12.25 -6.5'), "autocovariance on $a";
  is_pdl $a->acf(4), pdl('1 0.7 0.41212121 0.14848485 -0.078787879'), "autocorrelation on $a";
  is_pdl $a->filter_ma(2), pdl( '.6 1.2 2 3 4 5 6 7 7.8 8.4'), "filter moving average on $a";
  is_pdl $a->filter_exp(.8), pdl('0 0.8 1.76 2.752 3.7504 4.75008 5.750016 6.7500032 7.7500006 8.7500001'), "filter with exponential smoothing on $a";
  is_pdl $a->acf(5)->portmanteau($a->nelem), pdl( 11.1753902662994 ), "portmanteau significance test on $a";
  my $b = pdl '1 2 3 4 5 6 7 9 9 10';
  is_pdl $b->mape($a), pdl( 0.302619047619048 ), "mean absolute percent error between $a and $b";
  is_pdl $b->mae($a), pdl( 1.1 ), "mean absolute error between $a and $b";
  $b = $b->setbadat(3);
  is_pdl $b->mape($a), pdl( 0.308465608465608 ), "mean absolute percent error with bad data between $a and $b";
  is_pdl $b->mae($a), pdl( 1.11111111111111 ), "mean absolute error with bad data between $a and $b";
}

{
  my $a = sequence(5)->dummy(1,2)->flat->sever;
  is_pdl $a->dseason(5), pdl('0.6 1.2 2 2 2 2 2 2 2.8 3.4'), "deseasonalize data on $a with period 5";
  is_pdl $a->dseason(4), pdl('0.5 1.125 2 2.375 2.125 1.875 1.625 2 2.875 3.5'), "deseasonalize data on $a with period 4";
  $a = $a->setbadat(4);
  is_pdl $a->dseason(5), pdl('0.6 1.2 1.5 1.5 1.5 1.5 1.5 2 2.8 3.4'), "deseasonalize data with bad data on $a with period 5";
  is_pdl $a->dseason(4), pdl('0.5 1.125 2  1.8333333 1.5  1.1666667 1.5 2 2.875 3.5'), "deseasonalized data with bad data on $a with period 4";
}

{
  my $a = pdl '0 1 BAD 3; 4 5 BAD 7';
  my $a_ans = pdl( [qw( 0 1 1.75 3)], [qw( 4 5 5.75 7 )], );
  is_pdl $a->fill_ma(2), $a_ans, "fill missing data with moving average";
}

{
  my $x = sequence 2;
  my $b = pdl(.8, -.2, .3);
  my $xp = $x->pred_ar($b, 7);
  is_pdl $xp, pdl('[[0 1 1.1 0.74 0.492 0.3656 0.31408]]'), "predict autoregressive series";
  my $xp2 = $x->pred_ar(pdl(.8, -.2), 7, {const=>0});
  is_pdl $xp2, pdl('[[0 1 0.8 0.44 0.192 0.0656 0.01408]]'), "predict autoregressive series w/no constant last value";
}

{
  my $a = sequence 10;
  my $b = pdl( qw(0 1 1 1 3 6 7 7 9 10) );
  is_pdl $a->wmape($b), pdl(0.177777777777778), "weighted mean absolute percent error between $a and $b";
  $a = $a->setbadat(4);
  is_pdl $a->wmape($b), pdl(0.170731707317073), "weighted mean absolute percent error with bad data between $a and $b";
}

{
  my $a = pdl '0 3 2 3 4 0 1 2 3 4 0 1 2 3 4; 0 3 2 3 0 0 1 2 3 4 0 1 2 3 4';
  my $ans_m = pdl('4 0 1.6666667 2 3; 2.6666667 0 1.6666667 2 3');
  my $ans_ms = pdl('0 0 0.88888889 0 0; 3.5555556 0 0.88888889 0 0');
  my ($m, $ms) = $a->season_m( 5, {start_position=>1, plot=>0} );
  is_pdl $m, $ans_m, 'season_m m';
  is_pdl $ms, $ans_ms, 'season_m ms';
}

done_testing;
