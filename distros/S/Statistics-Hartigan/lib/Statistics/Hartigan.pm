package Statistics::Hartigan;

use 5.008005;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT = qw( hartigan );

our $VERSION = '0.01';

# global variable
my @H = ();
my @d = ();
my @W = ();
my $rcnt = 0;

sub hartigan
{
    # Input params
    my $matrixfile = shift;
    my $clustmtd = shift;
    my $K = shift;
    my $threshold = shift;

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

    my %hash = ();

    # Calculate all possible unique pairwise distances between the vectors
    for($i = 0; $i < $rcnt; $i++)
    {
	# for all the rows in the cluster
	for($j = $i+1; $j < $rcnt; $j++)
	{
	    @row1 = @{$inpmat[$i]};
	    @row2 = @{$inpmat[$j]};
	    $d[$i][$j] = &dist_euclidean_sqr(\@row1, \@row2);
	}
	$hash{0} .= "$i ";
    }
    
    $hash{0} = substr($hash{0},0,length($hash{0})-1);
    $W[1] = &WGSS(\%hash);

    my $k = 0;
    my $flag = 0;

    # For each K
    for($k=1; $k<$K; $k++)
    {
	my $lineNo = 0;
	my %hash = ();

	# Cluster the input dataset into k+1 clusters
	my $status = 0;
	my $next_k = $k + 1;
	$status = system("vcluster --clmethod $clustmtd $matrixfile $next_k >& tmpfile");
	die "Error running vcluster \n" unless $status==0;

	# read the clustering output file
	open(CO,"<$matrixfile.clustering.$next_k") || die "Error opening clustering output file.";

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

	# Calculate the "Within Cluster Sum of Squared W(k+1)
	# for given matrix and k+1 value.
	$W[$next_k] = &WGSS(\%hash);

	unlink "$matrixfile.clustering.$next_k", "tmpfile","$matrixfile.tree";	

	if($W[$next_k] == 0)
	{
	    print $next_k . "\n";
	    $flag = 1;
	    last;
	}
	else
	{
	    $H[$k] = ( $W[$k]/$W[$next_k] - 1 ) * ( $rcnt - $k - 1 );
	    $H[$k] = sprintf("%.4f",$H[$k]);	
	}

	if($H[$k] <= $threshold)
	{
	    print $k . "\n";
	    $flag = 1;
	    last;
	}
    }

    if(!$flag)
    {
	print "NAN\n";
    }
}

sub WGSS
{
    # Input arguments
    my %clustout = %{(shift)};

    # Local variables
    my $i; 
    my $j;
    my @rownum;
    my $key;
    my $row1;
    my $row2;
    my @D = ();
    my $W = 0;

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

	$W += ( $#rownum - 1 ) * $D[$key];
    }

    $W = $W/2;

    return $W;
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


1;
__END__

=head1 NAME

Statistics::Hartigan - Perl extension for the stopping rule proposed by Hartigan J.
Hartigan, J. (1975). Clustering Algorithms. John Wiley and Sons, New York, NY, US.

=head1 SYNOPSIS

  use Statistics::Hartigan;
  &hartigan(InputFile, "agglo", 6, 10);

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

Hartigan J. uses the Within Cluster/Group Sum of Squares (WGSS) 
to estimate the number of clusters a given data
naturally falls into. The is goal is to minimize WGSS.

=head2 EXPORT

"hartigan" function by default.

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

=head2 Threshold value

A threshold needs to be specified for this stopping rule to stop :)
A typical value (empirically found) is 10. 

=head1 OUTPUT

A single integer number which is the estimate of number of clusters present in the input dataset.

=head1 PRE-REQUISITES

1. This module uses suite of C programs called CLUTO for clustering purposes. 
Thus CLUTO needs to be installed for this module to be functional.
CLUTO can be downloaded from http://www-users.cs.umn.edu/~karypis/cluto/

=head1 SEE ALSO

1. Hartigan, J. (1975). Clustering Algorithms. John Wiley and Sons, New York, NY, US.
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
