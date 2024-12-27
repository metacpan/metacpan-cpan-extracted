use strict;
use warnings;
use Test::More;
use PDL::Stats::Basic;
use PDL::Stats::Kmeans;
use PDL::LiteF;
use PDL::NiceSlice;
use Test::PDL qw(is_pdl eq_pdl);

{
  my $a = iv_cluster( [qw(a a b b)] );
  is_pdl $a, pdl([1,1,0,0], [0,0,1,1]), 'independent variable cluster';
}

is_pdl scalar iv_cluster([qw(a a BAD b b)]), pdl('1 1 BAD 0 0;0 0 BAD 1 1'),
  'independent variable cluster with bad data';

is_pdl +(sequence(4,3) % 2)->assign(xvals(2,3)), short('1 0 1 0; 0 1 0 1');

{
  my ($m, $ss) = sequence(4,3)->centroid(byte([1,0,1,0], [0,1,0,1]));
  is_pdl $m, pdl([1,2], [5,6], [9,10]), "centroid";
  is_pdl $ss, ones(2,3) * 2, "centroid";
}

{
  my $centroid = pdl( [0,1], [0,1], [0,1] );
  my $a = pdl '0 1 0 1 BAD; 1 0 1 0 1; 0 1 0 1 BAD';
  is_pdl $a->assign($centroid), short([1,0,1,0,0], [0,1,0,1,1]),
    "assign with bad data";
}

{
  my $a = pdl '0 1 2 3 BAD; 5 6 7 8 9; 10 11 12 13 BAD';
  my $cluster = pdl(byte, [1,0,1,0,0], [0,1,0,1,1]);
  my ($m, $ss) = $a->centroid($cluster);
  my $m_a = pdl([1,2], [6,7.6666667], [11,12]);
  my $ss_a = pdl([1,1], [1,1.5555556], [1,1]);
  is_pdl $m, $m_a, "centroid with bad data";
  is_pdl $ss, $ss_a, "centroid with bad data";
}

# kmeans is undeterministic. retry to for optimal results
ok(t_kmeans_with_retry(), 't_kmeans');
sub t_kmeans_with_retry {
    for my $retry (1..3) {
        return 1 if t_kmeans();
    }
}
sub t_kmeans {
  my $data = pdl '0 0 2 3 4 5 6; 7 0 9 10 11 12 13; 14 0 16 17 18 19 20';
  my %m = $data->kmeans({NCLUS=>2, NSEED=>6, NTRY=>10, V=>0});
  eq_pdl $m{centroid}->sumover, pdl qw(3.3333333  10.333333  17.333333);
}

{
  my $data = pdl '
   [
    [0 0 2 3 4 5 6; 0 0 9 10 11 12 13; 14 0 16 17 18 19 20]
    [21 0 23 24 25 26 27; 28 0 30 31 32 33 34; 35 0 37 38 39 40 41]
   ]
   [
    [0 0 44 45 46 47 48; 0 0 51 52 53 54 55; 56 0 58 59 60 61 62]
    [63 0 65 66 67 68 69; 70 0 72 73 74 75 76; 77 0 79 80 81 82 83]
   ]
  ';
  my %m = $data->kmeans( {nclus=>[2,1,1], ntry=>20, v=>0} );
#  print "$_\t$m{$_}\n" for (sort keys %m);
  my %a = (
    'R2'  => pdl
(
  [ qw(0.74223245 0.97386667) ],
  [ qw(0.84172845 0.99499377) ],
),
    'ss_sum'  => pdl (
[
 [ qw(        10         10        108 )],
 [ qw( 23.333333  23.333333  23.333333 )],
],
[
 [ qw(        10         10       1578 )],
 [ qw( 23.333333  23.333333  23.333333 )],
]
           ),
  );
  is_pdl $m{R2}, $a{R2}, "kmeans R2 result as expected";
  is_pdl $m{ss}->sumover, $a{ss_sum}, {atol=>1e-3, test_name=>"kmeans ss result as expected"};
}

{
  my $data = pdl '
   [
    [0 0 2 3 4 5 6; 0 0 9 10 11 12 13; 14 0 16 17 18 19 20]
    [21 0 23 24 25 26 27; 28 0 30 31 32 33 34; 35 0 37 38 39 40 41]
   ]
   [
    [0 0 44 45 46 47 48; 0 0 51 52 53 54 55; 56 0 58 59 60 61 62]
    [63 0 65 66 67 68 69; 70 0 72 73 74 75 76; 77 0 79 80 81 82 83]
   ]
  ';
    # centroid intentionally has one less dim than data
  my $centroid = pdl('[10 0; 10 0; 10 0] [20 0; 30 0; 30 0]');
    # use dummy to match centroid dims to data dims
  my %m = $data->kmeans( {cntrd=>$centroid->dummy(-1), v=>0} );
#  print "$_\t$m{$_}\n" for (sort keys %m);
  my %a = (
    R2  => pdl('0.74223245 0.97386667; 0.84172845 0.99499377'),
    ss_sum  => pdl('
      [10 10 108; 23.333333 23.333333 23.333333]
      [10 10 1578; 23.333333 23.333333 23.333333]
    '),
  );
  is_pdl $m{R2}, $a{R2}, "kmeans R2 with manually seeded centroid";
  is_pdl $m{ss}->sumover, $a{ss_sum}, {atol=>1e-3, test_name=>"kmeans ss with manually seeded centroid"};
}

TODO: {
local $TODO = 'kmeans is undeterministic. retry to for optimal results';
ok t_kmeans_bad_with_retry(), 't_kmeans_bad';
}
sub t_kmeans_bad_with_retry {
    for my $retry (1..3) {
        return 1 if t_kmeans_bad();
    }
}
sub t_kmeans_bad {
  my $data = sequence 7, 3;
  $data = $data->setbadat(4,0);
  my %m = $data->kmeans({NCLUS=>2, NTRY=>10, V=>0});
  #print "$_\t$m{$_}\n" for (sort keys %m);
  eq_pdl $m{ms}->sumover, pdl qw( 1.5  1.9166667  1.9166667 );
}

{
  my $data = pdl '
    [0 0 2 BAD 4 5 6; 0 0 9 10 11 12 13; 0 0 16 17 18 19 20]
    [21 22 23 24 1 1 1; 28 29 30 31 1 1 1; 35 36 37 38 1 1 1]
  ';
  my %m = $data->kmeans( {nclus=>[2,1], ntry=>20, v=>0} );
#  print "$_\t$m{$_}\n" for (sort keys %m);
  my %a = (
    'R2'  => pdl( [ qw( 0.96879592 0.99698988 ) ] ),
    'ms'  => pdl('[2.1875 0; 2 0; 2 0] [0,1.25; 0 1.25; 0 1.25]'),
  );
  is_pdl $m{R2}, $a{R2}, "3d kmeans with bad data R2 is as expected";
  is_pdl $m{ms}->sumover, $a{ms}->sumover, {atol=>1e-3, test_name=>"3d kmeans with bad data ss is as expected"};
}

{
  my $l = pdl(
[qw( -0.798603   -0.61624  -0.906765   0.103116)],
[qw(  0.283269   -0.41041   0.131113   0.894118)],
[qw( -0.419717   0.649522 -0.0223668   0.434389)],
[qw(  0.325314   0.173015  -0.400108  0.0350236)],
  );
  my $c = $l->pca_cluster({v=>0,ncomp=>4,plot=>0});
  is_pdl $c, pdl([1,0,1,0], [0,1,0,0], [0,0,0,1]),
    "principal component analysis clustering";
}

{
  my $a = pdl( [[3,1], [2,4]] );
  my $b = pdl( [2,4], [3,1] );
  my $c = pdl( 5,15 );
  my $d = PDL::Stats::Kmeans::_d_point2line( $a, $b, $c );
  is_pdl $d, pdl(1.754116, 1.4142136), '_d_point2line';
}

{
  my $c0 = pdl(byte, [1,0,1,0], [0,1,0,1]);
  my $c1 = pdl(byte, [0,0,0,1], [0,1,1,0]);
  my $c = cat $c0, $c1;
  my $ans = indx( [0,1,0,1], [-1,1,1,0] );
  is_pdl $c->which_cluster, $ans, 'which_cluster';
}

done_testing();
