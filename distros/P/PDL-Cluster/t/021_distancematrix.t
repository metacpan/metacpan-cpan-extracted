#-*- Mode: CPerl -*-
use Test::More tests=>8;

my $TEST_DIR;
BEGIN {
  use File::Basename;
  use Cwd;
  $TEST_DIR = Cwd::abs_path dirname( __FILE__ );
  eval qq{use lib ("$TEST_DIR/$_/blib/lib","$TEST_DIR/$_/blib/arch");} foreach (qw(..));
  #do "$TEST_DIR/common.plt" or die("$0: failed to load $TEST_DIR/common.plt: $@");
}

use PDL;
use PDL::Cluster;

#------------------------------------------------------
# Data for Tests
# 

#----------
# dataset
#
my $weight = pdl [ 1,1,1,1,1 ];
my $data   = pdl [
        [ 1.1, 2.2, 3.3, 4.4, 5.5, ], 
        [ 3.1, 3.2, 1.3, 2.4, 1.5, ], 
        [ 4.1, 2.2, 0.3, 5.4, 0.5, ], 
        [ 12.1, 2.0, 0.0, 5.0, 0.0, ], 
];
my $mask = pdl [
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
];

#------------------------------------------------------
# test sub
sub test_distancematrix {
  my %params = @_;
  my ($dists);

  PDL::Cluster::distancematrix(
			       $params{data},
			       $params{mask},
			       $params{weight},
			       ($dists=null),
			       $params{dist},
			      );

  my $label = $params{label} || 'distancematrix';

  is($dists->dim(0), $params{data}->dim(1), "$label: dists.dim(0)==data.dim(1)");
  is($dists->dim(1), $params{data}->dim(1), "$label: dists.dim(1)==data.dim(1)");

  if (defined(my $want = $params{expect})) {
    ##-- $want = [[$i,$j,$d],...]
    $want = pdl($want);
    for (my $wi=0; $wi < $want->dim(1); ++$wi) {
      my $want_ij = $want->slice("0:1,($wi)");
      my $want_d  = $want->slice("(2),($wi)");
      is($dists->indexND($want_ij)->string("%.3f"), $want_d->string("%.3f"), "$label: dists($want_ij)");
    }
  }

  return $dists;
}


#------------------------------------------------------
# Tests
# 

#----------
# test dataset with transpose==0
#

test_distancematrix(
		    transpose =>        0,
		    dist      =>      'e',
		    data      =>    $data,
		    mask      =>    $mask,
		    weight    =>  $weight,
		    label     => 'distancematrix',
		    expect    => [
				  [1,0, 5.8],
				  [2,0, 8.8],
				  [2,1, 2.6],
				  [3,0, 32.508],
				  [3,1, 18.628],
				  [3,2, 12.908],
				 ]);

##----------
## test dataset with transpose==1 : DISABLED
##
#$matrix = PDL::Cluster::distancematrix(
#	transpose =>        1,
#	dist      =>      'e',
#	data      =>    $data,
#	mask      =>    $mask,
#	weight    =>  $weight,
#;

##----------
## Make sure that the length of $matrix matches the length of @data1
##want = scalar @{$data->[0]};       test q( scalar @$matrix );

##----------
## Test the values in the distance matrix


#$want = ' 26.71';       test q( sprintf "%6.2f", $matrix->[1]->[0] );
#$want = ' 42.23';       test q( sprintf "%6.2f", $matrix->[2]->[0] );
#$want = '  3.11';       test q( sprintf "%6.2f", $matrix->[2]->[1] );
#$want = ' 15.87';       test q( sprintf "%6.2f", $matrix->[3]->[0] );
#$want = '  6.18';       test q( sprintf "%6.2f", $matrix->[3]->[1] );
#$want = ' 13.36';       test q( sprintf "%6.2f", $matrix->[3]->[2] );
#$want = ' 45.32';       test q( sprintf "%6.2f", $matrix->[4]->[0] );
#$want = '  5.17';       test q( sprintf "%6.2f", $matrix->[4]->[1] );
#$want = '  1.23';       test q( sprintf "%6.2f", $matrix->[4]->[2] );
#$want = ' 12.76';       test q( sprintf "%6.2f", $matrix->[4]->[3] );


__END__



