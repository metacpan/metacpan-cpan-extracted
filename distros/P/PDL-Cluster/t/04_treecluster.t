#-*- Mode: CPerl -*-
use Test::More tests=>16;

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
# dataset 1
#
my $weight1 = pdl [ 1,1,1,1,1 ];
my $data1   = pdl [
        [ 1.1, 2.2, 3.3, 4.4, 5.5, ], 
        [ 3.1, 3.2, 1.3, 2.4, 1.5, ], 
        [ 4.1, 2.2, 0.3, 5.4, 0.5, ], 
        [ 12.1, 2.0, 0.0, 5.0, 0.0, ], 
];
my $mask1 = pdl [
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
        [ 1, 1, 1, 1, 1, ], 
];

#----------
# dataset 2
#
my $weight2 = pdl [ 1,1 ];
my $data2   = pdl [
	[ 0.8223, 0.9295 ],
	[ 1.4365, 1.3223 ],
	[ 1.1623, 1.5364 ],
	[ 2.1826, 1.1934 ],
	[ 1.7763, 1.9352 ],
	[ 1.7215, 1.9912 ],
	[ 2.1812, 5.9935 ],
	[ 5.3290, 5.9452 ],
	[ 3.1491, 3.3454 ],
	[ 5.1923, 5.3156 ],
	[ 4.7735, 5.4012 ],
	[ 5.1297, 5.5645 ],
	[ 5.3934, 5.1823 ],
];
my $mask2 = pdl [
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
	[ 1, 1 ],
];


#------------------------------------------------------
# Tests
# 
my ($result, $linkdist, $output);
my ($i);

#-----------
# tree-clustering test function
sub test_treecluster {
  my %params = @_;
  my ($result,$lnkdst);

  PDL::Cluster::treecluster(
			    $params{data},
			    $params{mask},
			    $params{weight},
			    #($result=null),
			    #($lnkdst=null),
			    ($result=zeroes(long,  2,$params{data}->dim(1))),
			    ($lnkdst=zeroes(double,  $params{data}->dim(1))),
			    $params{dist},
			    $params{method},
			   );

  ##-- parse expected value
  my ($expect_t,$expect_d) = @params{qw(expect_t expect_d)};
  if (!($expect_t && $expect_d) && $params{expect}) {
    my @expect = split(/\n/, $params{expect});
    my ($l,$r,$d);
    $expect_t = [];
    $expect_d = [];
    foreach (@expect) {
      chomp;
      next if (/^\s*$/);
      s/^\s*[0-9]+\://; ##-- trim index
      ($l,$r,$d) = split(' ',$_,3);
      push(@$expect_t, [$l,$r]);
      push(@$expect_d, $d);
    }
  }

  my $label = $params{label} || 'treecluster';
  is($result->slice(",0:-2")->qsort->string, pdl($expect_t)->long->qsort->string, "$label: tree");
  is($lnkdst->slice("0:-2")->string("%.3f"), pdl($expect_d)->string("%.3f"), "$label: lnkdist");

  return ($result,$lnkdst);
}


#----------
# test dataset 1
#

#--------------[PALcluster]-------
my %params = (
	      label => 'data1',
	      transpose  =>         0,
	      method     =>       'a',
	      dist       =>       'e',
	      data       =>    $data1,
	      mask       =>    $mask1,
	      weight     =>  $weight1,
	     );
test_treecluster(%params,label=>"data1:PALcluster",expect=>'
  0:   2   1   2.600
  1:  -1   0   7.300
  2:   3  -2  21.348
');

#--------------[PSLcluster]-------
$params{method} = 's';
test_treecluster(%params,label=>"data1:PSLcluster",expect=>'
  0:   2   1   2.600
  1:  -1   0   5.800
  2:   3  -2  12.908
');

#--------------[PCLcluster]-------
$params{method} = 'c';
test_treecluster(%params,label=>"data1:PCLcluster",expect=>'
  0:   1   2   2.600
  1:   0  -1   6.650
  2:  -2   3  19.437
');

#--------------[PMLcluster]-------
$params{method} = 'm';
test_treecluster(%params,label=>"data1:PMLcluster",expect=>'
  0:   2   1   2.600
  1:  -1   0   8.800
  2:   3  -2  32.508
');

#----------
# test dataset 2
#

#--------------[PALcluster]-------
%params = (
	transpose  =>         0,
	method     =>       'a',
	dist       =>       'e',
	data       =>    $data2,
	mask       =>    $mask2,
	weight     =>  $weight2,
);
test_treecluster(%params,label=>"data2:PALcluster",expect=>'
  0:   5   4   0.003
  1:   9  12   0.029
  2:   2   1   0.061
  3:  11  -2   0.070
  4:  -4  10   0.128
  5:   7  -5   0.224
  6:  -3   0   0.254
  7:  -1   3   0.391
  8:  -8  -7   0.532
  9:   8  -9   3.234
 10:  -6   6   4.636
 11: -11 -10  12.741
');

#print STDERR "\n$want\n\n$output\n";


#--------------[PSLcluster]-------
$params{method} = 's';
test_treecluster(%params,label=>"data2: PSLcluster",expect=>'
  0:   5   4   0.003
  1:   9  12   0.029
  2:  11  -2   0.033
  3:   2   1   0.061
  4:  -3  10   0.077
  5:   7  -5   0.092
  6:  -4   0   0.242
  7:  -1  -7   0.246
  8:   3  -8   0.287
  9:   8  -9   1.936
 10:  -6 -10   3.432
 11:   6 -11   3.535
');


#--------------[PCLcluster]-------
$params{method} = 'c';
test_treecluster(%params,label=>"data2:PCLcluster",expect=>'
  0:   4   5   0.003
  1:  12   9   0.029
  2:   1   2   0.061
  3:  -2  11   0.063
  4:  10  -4   0.109
  5:  -5   7   0.189
  6:   0  -3   0.239
  7:   3  -1   0.390
  8:  -7  -8   0.382
  9:  -9   8   3.063
 10:   6  -6   4.578
 11: -10 -11  11.536
');

#print FILE "$want\n$output";

#--------------[PMLcluster]-------
$params{method} = 'm';
($result, $linkdist) = test_treecluster(%params,label=>'data2: PMLcluster',expect=>'
  0:   5   4   0.003
  1:   9  12   0.029
  2:   2   1   0.061
  3:  11  10   0.077
  4:  -2  -4   0.216
  5:  -3   0   0.266
  6:  -5   7   0.302
  7:  -1   3   0.425
  8:  -8  -6   0.968
  9:   8   6   3.975
 10: -10  -7   5.755
 11: -11  -9  22.734
');
#print FILE "$want\n$output";

__END__
