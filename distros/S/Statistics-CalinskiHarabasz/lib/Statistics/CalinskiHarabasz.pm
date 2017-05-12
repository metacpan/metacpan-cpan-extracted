package Statistics::CalinskiHarabasz;

use 5.008005;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT = qw( ch );

our $VERSION = '0.01';

# global variable
my @d = ();
my $g_mean = 0;
my $rcnt = 0;

sub ch
{
    # Input params
    my $matrixfile = shift;
    my $clustmtd = shift;
    my $K = shift;

    my $i = 0;
    my $j = 0;

   # Read the matrix file into a 2 dimensional array.
    my @inpmat = ();
    open(INP,"<$matrixfile") || die "Error opening input matrix file!";

    # Extract the number of rows from the first line in the file.
    my $ccnt = 0;
    my $line;

    $line = <INP>;
    chomp($line);
    $line=~s/\s+/ /;
    
    ($rcnt,$ccnt) = split(/\s+/,$line);

    # Not a valid condition: 
    # If maximum number of clusters requested (k) is greater than the 
    # number of observations.
    if($K > $rcnt)
    {
	print STDERR "The K value ($K) cannot be greater than the number of observations present in the input data ($rcnt). \n";
	exit 1;
    }

    # Copy the complete matrix to a 2D array
    while(<INP>)
    {
	# remove the newline at the end of the input line
	chomp;

	# skip empty lines
	if(m/^\s*\s*\s*$/)
	{
	    next;
	}

	# remove leading white spaces
	s/^\s+//;

	# seperate individual values in a line
	my @tmp = ();
	@tmp = split(/\s+/);
	
	# populate them into the 2D matrix
	push @inpmat, [ @tmp ]; 
    }

    close INP;

    my @row1 = ();
    my @row2 = ();
    my $acc = 0;

    # Calculate all possible unique pairwise distances between the vectors
    for($i = 0; $i < $rcnt; $i++)
    {
	# for all the rows in the cluster
	for($j = $i+1; $j < $rcnt; $j++)
	{
	    @row1 = @{$inpmat[$i]};
	    @row2 = @{$inpmat[$j]};
	    $d[$i][$j] = &dist_euclidean_sqr(\@row1, \@row2);
	    $acc += $d[$i][$j];
	}
    }

    # Calculate general mean (d^2)
    $g_mean = ($acc * 2)/($rcnt *  ($rcnt - 1));

    # Calculate mean for each cluster
    # Calculate Ak
    # Calculate VRC (Variance Ratio Criterion)

    # For each K
    my $k = 0;
    my @VRC = ();

    for($k=2; $k<=$K; $k++)
    {
	# avoid the case K = #ofContexts because then the denominator of VRC (n-k)
	# become 0 and gives "division by 0" error.
	if($k == $rcnt)
	{
	    last;
	}

	my $lineNo = 0;
	my %hash = ();

	# Cluster the input dataset into k clusters
	my $out_filename = "tmp.op" . $k . time();
	my $status = 0;

	$status = system("vcluster --clmethod $clustmtd $matrixfile $k >& $out_filename  ");
	die "Error running vcluster \n" unless $status==0;

	# read the clustering output file
	open(CO,"<$matrixfile.clustering.$k") || die "Error opening clustering output file.";

	my $clust = 0;
	while($clust = <CO>)
	{
	    # hash on the cluster# and append the observation# 
	    chomp($clust);
	    if(exists $hash{$clust})
	    {
		$hash{$clust} .= " $lineNo";
	    }
	    else
	    {
		$hash{$clust} = $lineNo;
	    }

	    # increment the line number
	    $lineNo++;
	}

	close CO;

	# Calculate the "Within Cluster Dispersion Measure / Error Measure" Wk 
	# for given matrix and k value.
	$VRC[$k] = &variance_ratio(\%hash,$k);

	unlink "$out_filename","$matrixfile.clustering.$k";
    }

    # Calculate smallest k for which VRC is maximum   
    my $max = 0;
    my $ans = 0;
    for($k=2; $k<=$K; $k++)
    {
	# avoid the case K = #ofContexts because then the denominator of VRC (n-k)
	# become 0 and gives "division by 0" error.
	if($k == $rcnt)
	{
	    last;
	}
	if($VRC[$k] > $max)
	{
	    $max = $VRC[$k];
	    $ans = $k;
	}
    }
    print "$ans\n";
}

sub dist_euclidean_sqr
{
    # arguments
    my @i = @{(shift)};
    my @j = @{(shift)};

    # local variables
    my $a;
    my $dist = 0;
    my $retvalue = 0;

    # Squared Euclidean measure 
    # summation on all j (xij - xi'j)^2 where i, i' are the rows indicies.
    for $a (0 .. $#i)
    {
	$dist += (($i[$a] - $j[$a])**2);
    }

    $retvalue = sprintf("%.4f",$dist);	
    return $retvalue;
}

sub variance_ratio
{
    # Input arguments
    my %clustout = %{(shift)};
    my $k = shift;

    # Local variables
    my $i; 
    my $j;
    my @rownum;
    my $key;
    my $row1;
    my $row2;
    my $VRC = 0;
    my @D = ();
    my $tmp;
    my $c_mean = ();
    my $A = 0;

    # For each cluster
    foreach $key (sort keys %clustout)
    {
	$D[$key] = 0;

	@rownum = split(/\s+/,$clustout{$key});

	# for each instance in the cluster
	for($i = 0; $i < $#rownum; $i++)
	{
	    # for all the rows in the cluster
	    for($j = $i+1; $j <= $#rownum; $j++)
	    {
		# find the distance between the 2 rows of the matrix.
		$row1 = $rownum[$i];
		$row2 = $rownum[$j];

		# store the Dr value
		if(exists $d[$row1][$row2])
		{
		    $D[$key] += $d[$row1][$row2];
		}
		else
		{
		    $D[$key] += $d[$row2][$row1];
		}
	    }
	}

	# Calculate individual cluster mean
	if($#rownum == 0)
	{
	    $c_mean = 0;
	}
	else
	{
	    $c_mean = ($D[$key] * 2)/(($#rownum + 1) * $#rownum);
	}

	$A += $#rownum * ($g_mean - $c_mean);
    }

    $A = $A/($rcnt - $k);

    if($g_mean == $A)
    {
	$VRC = 99999;
    }
    else
    {
	$VRC = ( $g_mean + ($rcnt - $k) / ($k-1) * $A ) / ( $g_mean - $A ); 
    }
    return $VRC;
}

1;
__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Statistics::CalinskiHarabasz - Perl extension to the cluster stopping rule proposed by Calinski and Harabasz (C&H)

=head1 SYNOPSIS

  use Statistics::CalinskiHarabasz;
  &ch(InputFile, "agglo", 10);

  Input file is expected in the "dense" format -
  Sample Input file:
   
  6 5
  1       1       0       0       1
  1       0       0       0       0
  1       1       0       0       1
  1       1       0       0       1
  1       0       0       0       1
  1       1       0       0       1 	  	

=head1 DESCRIPTION

C&H use the Variance Ratio Criterion which is analogous to 
F-Statistics to estimate the number of clusters a given data
naturally falls into. They minimize Within Cluster/Group Sum
of Squares (WGSS) and maximize Between Cluster/Group Sum of 
Squares (BGSS)

=head2 EXPORT

"ch" function by default.

=head1 INPUT

=head2 InputFile

The input dataset is expected in "dense" matrix format.
The input dense matrix is expected in a plain text file where the first
line in the file gives the dimensions of the dataset and then the 
dataset in a matrix format should follow. The contexts / observations 
should be along the rows and the features should be along the column.

	eg:
      	6 5
        1       1       0       0       1
        1       0       0       0       0
        1       1       0       0       1
        1       1       0       0       1
        1       0       0       0       1
        1       1       0       0       1 	

The first line (6 5) gives the number of rows (observations) and the 
number of columns (features) present in the following matrix.
Following each line records the frequency of occurrence of the feature
at the column in the given observation. Thus features1 (1st column) occurs
once in the observation1 and infact once in all the other observations too 
while the feature3 does not occur in observation1.

=head2  ClusteringMethod

The Clustering Measures that can be used are:
1. rb - Repeated Bisections [Default]
2. rbr - Repeated Bisections for by k-way refinement
3. direct - Direct k-way clustering
4. agglo  - Agglomerative clustering
5. graph  - Graph partitioning-based clustering
6. bagglo - Partitional biased Agglomerative clustering

=head2  K value

This is an approximate upper bound for the number of clusters that may be
present in the dataset. Thus for a dataset that you expect to be seperated
into 3 clusters this value should be set some integer value greater than 3.

=head1 OUTPUT

A single integer number which is the estimate of number of clusters present in the input dataset.

=head1 PRE-REQUISITES

1. This module uses suite of C programs called CLUTO for clustering purposes. 
Thus CLUTO needs to be installed for this module to be functional.
CLUTO can be downloaded from http://www-users.cs.umn.edu/~karypis/cluto/

=head1 SEE ALSO

1. T. Calinski and J. Harabasz. A dendrite method for cluster analysis. Communications in statistics, 3(1):1--27, 1974.
2. http://www-users.cs.umn.edu/~karypis/cluto/

=head1 AUTHOR

Anagha Kulkarni, University of Minnesota Duluth
kulka020 <at> d.umn.edu
	
Guergana Savova, Mayo Clinic
savova.guergana <at> mayo.edu

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006, Guergana Savova and Anagha Kulkarni

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=cut
