#!/usr/bin/perl 

use strict;
use warnings;
use Test::More;

BEGIN {
      # 1-2
    use_ok( 'PDLA::Stats::Basic' );
    use_ok( 'PDLA::Stats::Kmeans' );
}

use PDLA::LiteF;
use PDLA::NiceSlice;

sub tapprox {
  my($a,$b, $eps) = @_;
  $eps ||= 1e-6;
  my $diff = abs($a-$b);
    # use max to make it perl scalar
  ref $diff eq 'PDLA' and $diff = $diff->max;
  return $diff < $eps;
}

is(tapprox( t_iv_cluster(), 0 ), 1);
sub t_iv_cluster {
  my @a = qw( a a b b );
  my $a = iv_cluster( \@a );
  return abs($a - pdl(byte, [1,1,0,0], [0,0,1,1]))->sum;
}

is(tapprox( t_iv_cluster_bad(), 0 ), 1);
sub t_iv_cluster_bad {
  my @a = qw( a a BAD b b );
  my $a = iv_cluster( \@a );

  is(sum(abs(which($a->isbad) - pdl(2,7))), 0, 'iv_cluster has bad value');
  return abs($a - pdl(byte, [1,1,-9,0,0], [0,0,-9,1,1]))->sum;
}

is(tapprox( t_assign(), 0 ), 1);
sub t_assign {
  my $centroid = pdl( [0,1], [0,1], [0,1] );
  my $a = sequence 4, 3;
  $a %= 2;
  my $c = $a->assign($centroid);
  my $cluster = pdl(byte, [1,0,1,0], [0,1,0,1]);
  return abs($c - $cluster)->sum;
}

is(tapprox( t_centroid(), 0 ), 1);
sub t_centroid {
  my $a = sequence 4, 3;
  my $cluster = pdl(byte, [1,0,1,0], [0,1,0,1]);
  my ($m, $ss) = $a->centroid($cluster);
  my $m_a = pdl([1,2], [5,6], [9,10]);
  my $ss_a = ones(2,3) * 2;
  return sum( $m - $m_a + ( $ss - $ss_a ) );
}

is(tapprox( t_assign_bad(), 0 ), 1);
sub t_assign_bad {
  my $centroid = pdl( [0,1], [0,1], [0,1] );
  my $a = sequence 5, 3;
  $a->setbadat(4,0);
  $a->setbadat(4,2);
  $a %= 2;
  my $c = $a->assign($centroid);
  my $cluster = pdl(byte, [1,0,1,0,0], [0,1,0,1,1]);
  return ($c - $cluster)->sum;
}

is(tapprox( t_centroid_bad(), 0 ), 1);
sub t_centroid_bad {
  my $a = sequence 5, 3;
  $a->setbadat(4,0);
  $a->setbadat(4,2);
  my $cluster = pdl(byte, [1,0,1,0,0], [0,1,0,1,1]);
  my ($m, $ss) = $a->centroid($cluster);
  my $m_a = pdl([1,2], [6,7.6666667], [11,12]);
  my $ss_a = pdl([1,1], [1,1.5555556], [1,1]);
  return sum( $m - $m_a + ( $ss - $ss_a ) );
}

# kmeans is undeterministic. retry to for optimal results
ok(t_kmeans_with_retry(), 't_kmeans');
sub t_kmeans_with_retry {
    for my $retry (1..3) {
        return 1 if (tapprox(t_kmeans(), 0))
    }
}
sub t_kmeans {
  my $data = sequence 7, 3;
  my $ind  = $data(1, )->flat;    # only works because $data is sequence
  $data = lvalue_assign_detour($data, $ind, 0);
  my %m = $data->kmeans({NCLUS=>2, NSEED=>6, NTRY=>10, V=>0});
  return sum( $m{centroid}->sumover - pdl qw(3.3333333  10.333333  17.333333) );
}

t_kmeans_4d();
sub t_kmeans_4d {
  my $data = sequence 7, 3, 2, 2;
  # construct ind from sequence, then call lvalue_assign_detour
  my $ind = sequence($data->dims)->(1, )->flat;
  $data = lvalue_assign_detour($data, $ind, 0);
  $ind = sequence($data->dims)->(0,1,0, )->flat;
  $data = lvalue_assign_detour($data, $ind, 0);
  $data = lvalue_assign_detour($data, which($data == 42), 0);
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

    # 9-10
  is(tapprox( sum( $m{R2} - $a{R2} ), 0 ), 1);
  is(tapprox( sum( $m{ss}->sumover - $a{ss_sum} ), 0, 1e-3 ), 1);
}

t_kmeans_4d_seed();
sub t_kmeans_4d_seed {
  my $data = sequence 7, 3, 2, 2;
  # construct ind from sequence, then call lvalue_assign_detour
  my $ind = sequence($data->dims)->(1, )->flat;
  $data = lvalue_assign_detour($data, $ind, 0);
  $ind = sequence($data->dims)->(0,1,0, );
  $data = lvalue_assign_detour($data, $ind, 0);
  $data = lvalue_assign_detour($data, which($data == 42), 0);

    # centroid intentially has one less dim than data
  my $centroid = pdl(
   [
    [qw( 10  0 )],
    [qw( 10  0 )],
    [qw( 10  0 )],
   ],
   [
    [qw( 20          0 )],
    [qw( 30          0 )],
    [qw( 30          0 )],
   ],
  );

    # use dummy to match centroid dims to data dims
  my %m = $data->kmeans( {cntrd=>$centroid->dummy(-1), v=>0} );
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

    # 11-12
  is(tapprox( sum( $m{R2} - $a{R2} ), 0 ), 1);
  is(tapprox( sum( $m{ss}->sumover - $a{ss_sum} ), 0, 1e-3 ), 1);
}

TODO: {
local $TODO = 'kmeans is undeterministic. retry to for optimal results';
is(t_kmeans_bad_with_retry(), 1, 't_kmeans_bad');
}
sub t_kmeans_bad_with_retry {
    for my $retry (1..3) {
        return 1 if (tapprox(t_kmeans_bad(), 0))
    }
}
sub t_kmeans_bad {
  my $data = sequence 7, 3;
  $data = $data->setbadat(4,0);
  my %m = $data->kmeans({NCLUS=>2, NTRY=>10, V=>0});
  print "$_\t$m{$_}\n" for (sort keys %m);
  return sum( $m{ms}->sumover - pdl qw( 1.5  1.9166667  1.9166667 ) );
}

t_kmeans_3d_bad();
sub t_kmeans_3d_bad {
  my $data = sequence 7, 3, 2;
  my $ind = sequence($data->dims)->(0:1, ,0)->flat;
  $data = lvalue_assign_detour($data, $ind, 0);
  $ind = sequence($data->dims)->(4:6, ,1)->flat;
  $data = lvalue_assign_detour($data, $ind, 1);
  $data->setbadat(3,0,0);
  my %m = $data->kmeans( {nclus=>[2,1], ntry=>20, v=>0} );
#  print "$_\t$m{$_}\n" for (sort keys %m);

  my %a = (
    'R2'  => pdl( [ qw( 0.96879592 0.99698988 ) ] ),
    'ms'  => pdl(
 [
  [2.1875,     0],
  [     2,     0],
  [     2,     0],
 ],
 [
  [   0,1.25],
  [   0,1.25],
  [   0,1.25],
 ]
           ),
  );

    # 14-15 
  is(tapprox( sum( $m{R2} - $a{R2} ), 0 ), 1);
  is(tapprox( sum( $m{ms} - $a{ms} ), 0, 1e-3 ), 1);
}

  # 16
is(tapprox( t_pca_cluster(), 0 ), 1);
sub t_pca_cluster {
  my $l = pdl(
[qw( -0.798603   -0.61624  -0.906765   0.103116)],
[qw(  0.283269   -0.41041   0.131113   0.894118)],
[qw( -0.419717   0.649522 -0.0223668   0.434389)],
[qw(  0.325314   0.173015  -0.400108  0.0350236)],
  );
  my $c = $l->pca_cluster({v=>0,ncomp=>4,plot=>0});
  return ( $c - pdl(byte, [1,0,1,0], [0,1,0,0], [0,0,0,1]) )->sum;
}
  # 17
{
  my $a = pdl( [[3,1], [2,4]] );
  my $b = pdl( [2,4], [3,1] );
  my $c = pdl( 5,15 );
  my $d = PDLA::Stats::Kmeans::_d_point2line( $a, $b, $c );

  is( tapprox(sum($d - pdl(1.754116, 1.4142136)), 0), 1, '_d_point2line');
}
  # 18
{
  my $c0 = pdl(byte, [1,0,1,0], [0,1,0,1]);
  my $c1 = pdl(byte, [0,0,0,1], [0,1,1,0]);
  my $c = cat $c0, $c1;
  my $ans = pdl( [0,1,0,1], [-1,1,1,0] );
  is( abs($c->which_cluster - $ans)->sum, 0, 'which_cluster');
}

done_testing();



sub lvalue_assign_detour {
    my ($pdl, $index, $new_value) = @_;

    my @arr = list $pdl;
    my @ind = ref($index)? list($index) : $index; 
    $arr[$_] = $new_value
        for (@ind);

    return pdl(\@arr)->reshape($pdl->dims)->sever;
}
