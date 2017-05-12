package Statistics::Gap;

use 5.008005;
use strict;
use warnings;
use POSIX qw(floor ceil);
use Math::BigFloat;
use Algorithm::RandomMatrixGeneration;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT = qw( gap );

our $VERSION = '0.10';

# Estimates the number of clusters that a given data naturally falls into
sub gap
{
    # input params
    my $prefix = shift;
	my $space = shift;		# vec/sim
    my $matrixfile = shift;
    my $clustmtd = shift;	# if vec then rb/rbr/direct/agglo/bagglo & sim then rb/rbr/direct/agglo
	my $crfun = shift;		# i1/i2/e1/h1/h2
    my $K = shift;
    my $B = shift;
	my $typeref = shift;	# B references (ref)/ B replicates (rep)
    my $percentage = shift;
	my $precision = shift;
	my $seed = shift;

	my $precision_str = '%.' . $precision . 'f';

    # read the input matrix file
    open(INP,"<$matrixfile") || die "Error opening input matrix file!\n";

    # extract the number of rows from the first line in the file.
    my $rcnt = 0;
    my $ccnt = 0;
    my $line;

    $line = <INP>;
    chomp($line);

	# remove leading white spaces
	$line=~s/^\s+//;

	my $format = 0; # determine the format of the input matrix - dense (0) / sparse (1)
	if($space eq "vec")
	{
		my @tmp = ();
		@tmp = split(/\s+/,$line);
		$rcnt = $tmp[0];
		$ccnt = $tmp[1];
		
		if($#tmp == 2)
		{
			$format = 1; #sparse
		}
	}
	else
	{
		my @tmp = ();
		@tmp = split(/\s+/,$line);
		$rcnt = $tmp[0];
		$ccnt = $tmp[0];
		
		if($#tmp == 1)
		{
			$format = 1; #sparse
		}
	}

    # Not a valid condition: 
    # If maximum number of clusters requested (k) is greater than the 
    # number of observations.
    if($K > $rcnt)
    {
		print STDERR "The K value ($K) cannot be greater than the number of observations present in the input data ($rcnt). \n";
		exit 1;
    }

    # find the row and column marginals for the input matrix
    my @rmar = ((0) x $rcnt);
    my @cmar = ((0) x $ccnt);

	if($format) # for sparse input format
	{
		my $row = 0;

		while(<INP>)
		{
			my $col = 0;

			# remove the newline at the end of the input line
			chomp;
			
			# for empty lines
			if(m/^\s*\s*\s*$/)
			{
				next;
			}
			else
			{
				# remove leading white spaces
				s/^\s+//;
				
				# seperate individual values in a line
				my @tmp = ();
				@tmp = split(/\s+/);
				
				for(my $i=0; $i<$#tmp; $i=$i+2)
				{
					$rmar[$row] += $tmp[$i+1];
					my $tmp_col = $tmp[$i] - 1;
					$cmar[$tmp_col] += $tmp[$i+1];					
				}
				
				$row++;
			}
		}
	}
	else # for dense input format
	{
		my $row = 0;
		while(<INP>)
		{
			my $col = 0;

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
			for(my $i=0; $i<$#tmp; $i++)
			{
				$rmar[$row] += $tmp[$i];
				$cmar[$i] += $tmp[$i];
			}
			
			$row++;
		}
	}

    close INP;

    #~~~~~ Step 1: Find the crfun value per k for the observed data ~~~~~~~~

    my @W = ();   # holds the crfun values for various k values

    # loop through K times
    for(my $k=1; $k<=$K; $k++)
    {
		# cluster the input matrix(nXm) i.e. cluster n observations into k clusters
		my $out_filename = "$prefix.tmp.op" . $k . time();

		if($space eq "vec")
		{
			my $status = system("vcluster --clmethod $clustmtd --crfun $crfun --colmodel none --rowmodel none $matrixfile $k >& $out_filename ");
			die "Error running vcluster. \n" unless $status==0;
		}
		else
		{
			my $status = system("scluster --clmethod $clustmtd --crfun $crfun $matrixfile $k >& $out_filename ");
			die "Error running scluster. \n" unless $status==0;			
		}

		# read the clustering output file
		open(CO,"<$out_filename") || die "Error opening clustering output file.\n";
		
		# read the complete file in one command
		my $temp = $/;
		$/ = undef;
		my $str = <CO>;
		$/ = $temp;
		close CO;
    
		# read the crfun value
		$str =~ /\-way clustering: \[.*=(.*?)\]/;
		$W[$k] = $1;

		unlink "$out_filename","$matrixfile.clustering.$k";
    }
	

    #~~~~~~~~~~~~~~~~~~~~ Step 2: Generation of Reference Model  ~~~~~~~~~~~~~~~~~~~~~~~~

    my @W_M = ();		# holds the crfun values for various k for the reference data.

	if($typeref eq "rep") #replicates
	{
		# Generate the Reference Distribution
		my @refmat = ();
		if(!defined $seed)
		{
			@refmat = generateMatrix(\@rmar, \@cmar, $precision);
		}
		else
		{
			@refmat = generateMatrix(\@rmar, \@cmar, $precision, $seed);
		}

		# Perform Monte Carlo Sampling B times from the generated distribution
		for(my $i = 1; $i <= $B; $i++)
		{
			my @replicate = ();
		
			for(my $j = 0; $j < $rcnt; $j++)
			{				
				my $rand = int(rand($rcnt));
				push @replicate, $refmat[$rand];
			}
		
			# compute total number of elements in @replicate
			my $totalElem = 0;
			for(my $j=0; $j<$rcnt; $j++)
			{
				for(my $k=0; $k<$ccnt; $k++)
				{
					if(defined $replicate[$j]->[$k])
					{
						$totalElem++;
					}
				}
			}
			
			# 1. Cluster the generated replicate
			# 2. Calculate the crfun value
			
			# Write the matrix to a temporary file
			my $filename = "$prefix.tmp.ref." . time() . $i;
			open(RO,">$filename") || die "Error opening temporary file ($filename) in write mode.\n";
			
			if($space eq "vec")
			{
				print RO $rcnt . "	 " . $ccnt  . "   " . $totalElem . "\n";
			}
			else
			{
				print RO $rcnt . "	 " . $totalElem . "\n";
			}
			
			for(my $j=0; $j<$rcnt; $j++)
			{
				for(my $k=0; $k<$ccnt; $k++)
				{
					if(defined $replicate[$j]->[$k])
					{
						my $tmp_col = $k+1;
						print RO "$tmp_col $replicate[$j]->[$k] ";
					}
				}
				print RO "\n";
			}

			close RO;
			
			for(my $k=1 ; $k<=$K ; $k++)
			{
				# cluster the replicate into 1..K clusters
				my $out_filename = "$prefix.tmp.ref.op." . $k . "." . time();

				if($space eq "vec")
				{
					my $status = 0;
				    $status = system("vcluster --clmethod $clustmtd --crfun $crfun --rowmodel none --colmodel none $filename $k >& $out_filename");
#					print "vcluster --clmethod $clustmtd --crfun $crfun --rowmodel none --colmodel none $filename $k >& $out_filename\n";
#					exit;
					die "Error running vcluster \n" unless $status==0;
				}
				else
				{
					my $status = system("scluster --clmethod $clustmtd --crfun $crfun $filename $k >& $out_filename");
					die "Error running scluster \n" unless $status==0;
				}

				# read the clustering output file
				open(CO,"<$out_filename") || die "Error opening clustering output file.\n";
				
				# read the complete file in one command
				my $temp = $/;
				$/ = undef;
				my $str = <CO>;
				$/ = $temp;
				close FP;
				
				# read the crfun value
				$str =~ /\-way clustering: \[.*=(.*?)\]/;
				$W_M[$i][$k] = $1;
				
				unlink "$out_filename","$filename.clustering.$k";
			}

			unlink "$filename", "$filename.tree";
		} # for $B
	}
	else # typeref = ref
	{
		# Generate B reference distributions
		for(my $i = 1; $i <= $B; $i++)
		{
			my @refmat = ();

			if(!defined $seed)
			{
				@refmat = generateMatrix(\@rmar, \@cmar, $precision);
			}
			else
			{
				@refmat = generateMatrix(\@rmar, \@cmar, $precision, $seed);
			}

			# compute total number of elements in @replicate
			my $totalElem = 0;
			for(my $j=0; $j<$rcnt; $j++)
			{
				for(my $k=0; $k<$ccnt; $k++)
				{
					if(defined $refmat[$j]->[$k])
					{
						$totalElem++;
					}
				}
			}
			
			# 1. Cluster the generated reference distributions
			# 2. Calculate the crfun
			
			# Write the matrix to a temporary file
			my $filename = "$prefix.tmp.ref." . time() . $i;
			open(RO,">$filename") || die "Error opening temporary file ($filename) in write mode.\n";
			# print the dimensions of the matrix to the file.		
			if($space eq "vec")
			{
				print RO $rcnt . "	 " . $ccnt  . "   " . $totalElem . "\n";
			}
			else
			{
				print RO $rcnt . "	 " . $totalElem . "\n";
			}
			
			for(my $j=0; $j<$rcnt; $j++)
			{
				for(my $k=0; $k<$ccnt; $k++)
				{
					if(defined $refmat[$j]->[$k])
					{
						my $tmp_col = $k+1;
						print RO "$tmp_col $refmat[$j]->[$k] ";
					}
				}
				print RO "\n";
			}

			close RO;
			
			for(my $k=1 ; $k<=$K ; $k++)
			{
				# cluster the generated reference into 1..K clusters
				my $out_filename = "$prefix.tmp.ref.op." . $k . "." . time();

				if($space eq "vec")
				{
					my $status = system("vcluster --clmethod $clustmtd --crfun $crfun --rowmodel none --colmodel none $filename $k >& $out_filename");
					die "Error running vcluster \n" unless $status==0;
				}
				else
				{
					my $status = system("scluster --clmethod $clustmtd --crfun $crfun $filename $k >& $out_filename");
					die "Error running scluster \n" unless $status==0;
				}

				# read the clustering output file
				open(CO,"<$out_filename") || die "Error opening clustering output file.\n";
				
				# read the complete file in one command
				my $temp = $/;
				$/ = undef;
				my $str = <CO>;
				$/ = $temp;
				close FP;
				
				# read the crfun value
				$str =~ /\-way clustering: \[.*=(.*?)\]/;
				$W_M[$i][$k] = $1;
				
				unlink "$out_filename","$filename.clustering.$k";
			}

			unlink "$filename", "$filename.tree";
		} # for $B
	} #else typeref = ref

	# For plots
	open(G3a,">$prefix.exp.dat") || die "Error creating $prefix.exp.dat file\n";
	open(G3b,">$prefix.obs.dat") || die "Error creating $prefix.obs.dat file\n";

    my @sum = ();
    my @gap = ();
 
    # Calculate average over the B crfun(exp) values
    for(my $i = 1; $i <= $K; $i++)
    {
		for(my $j = 1; $j <= $B; $j++)
		{
			$sum[$i] += $W_M[$j][$i];
		}
	   
		$sum[$i] = sprintf($precision_str,$sum[$i]/$B) + 0;

		# Calculate Gap(k) = crfun(obs) - avg_crfun(exp)
		$gap[$i] = sprintf($precision_str, $W[$i] - $sum[$i]) + 0;

		print G3a "$i $sum[$i]\n";
		print G3b "$i $W[$i]\n";

    }

	close G3a;
	close G3b;

    #~~~~~~~~~~~~~~~~~~~~ Step 3: Calculation of Standard Deviation  ~~~~~~~~~~~~~~~~~~~~~~~~
    
    my @sd = ();
    my @s = ();
	my $lower = 0;
	my $upper = 0;

	# For plot
	open(G4,">$prefix.gap.dat") || die "Error creating $prefix.gap.dat file\n";

    # Calculate standard deviation sd for crfun(exp)
    for(my $i = 1; $i <= $K; $i++)
    {
		for(my $j = 1; $j <= $B; $j++)
		{
			$sd[$i] += ($W_M[$j][$i] - $sum[$i])**2;
		}
		
		$sd[$i] = sprintf($precision_str,sqrt($sd[$i]/$B)) + 0;

		# Calculate the modified standard deviation to account for 
		# simulation error.
		$s[$i] = $sd[$i] * sqrt(1 + 1/$B);
		$s[$i] = sprintf($precision_str,$s[$i]) + 0;

		$lower = $gap[$i] - $s[$i];
		$upper = $gap[$i] + $s[$i];
		print G4 "$i $gap[$i] $lower $upper\n";
    }

	close G4;

    my $ans = 1;

    # Find the optimal #of k
	# for e1 
	if($crfun eq "e1")
	{		
		for(my $i = 2; $i < $K; $i++)
		{
			if($gap[$i] <= ($gap[$i+1] + $s[$i+1]))
			{
				$ans = $i;
				last;
			}
		}
	} # e1 - end
	elsif($crfun eq "i2" || $crfun eq "i1") # for i2
	{
		for(my $i = 1; $i < $K; $i++)
		{
			if($gap[$i] >= $gap[$i+1] - $s[$i+1])
			{
				$ans = $i;
				last;
			}
		}
	} # i2 - end
	elsif($crfun eq "h2" || $crfun eq "h1") # for h2
	{
		for(my $i = 2; $i < $K; $i++)
		{
			if($gap[$i] < 0)
			{
				next;
			}
	
			if($gap[$i] >= $gap[$i+1] - $s[$i+1])
			{
				$ans = $i;
				last;
			}
		}
	} # h2 - end

    # Printing to the log file.
    open(LO,">$prefix.gap.log") || die "Error opening the Log file ($prefix.gap.log) in write mode.\n";    

    # Print the confidence intervals
    my $alpha = 0;
    my $low_conf_int = 0;
    my $upp_conf_int = 0;
    my @tmp = ();

    printf LO "%3s  %10s  %10s  %10s  %10s  %10s  %30s\n", "K", "Gap(k)", "Obs($crfun(k))", "Exp($crfun(k))", "sd(k)", "s(k)", "$percentage% Confidence Intervals";   
    printf LO "-" x 95 ."\n";
    for(my $i = 1; $i <= $K; $i++)
    {
		# Calculate a from 100(1-2a) = %
		$alpha = (1 - $percentage/100)/2;
		
		for(my $j = 1; $j <= $B; $j++)
		{
			$tmp[$j-1] = $W_M[$j][$i];
		}
		# sort in the numeric ascending order 
		@tmp = sort {$a <=> $b} (@tmp);    
		
		# Calculate lower bound
		$low_conf_int = ($tmp[floor($B*$alpha)-1] + $tmp[ceil($B*$alpha)-1])/2;
		
		# Calculate upper bound
		$upp_conf_int = ($tmp[floor($B*(1-$alpha))-1] + $tmp[ceil($B*(1-$alpha))-1])/2;
		
		printf LO "%3d  %10.4f  %10.4f  %10.4f  %10.4f  %10.4f  %30s\n", $i, $gap[$i], $W[$i], $sum[$i], $sd[$i], $s[$i], "$low_conf_int - $upp_conf_int";
    }

    print LO "\nIndividual Exp($crfun(k)) values:\n";
    for(my $i = 1; $i <= $K; $i++)
    {
		print LO "K=$i\n";
		printf LO "%3s  %10s\n", "B", "crfun"; 
		printf LO "-" x 15 . "\n"; 
		for(my $j = 1; $j <= $B; $j++)
		{
			$tmp[$j-1] = $W_M[$j][$i];
			printf LO "%3s  %10s\n", "$j", "$W_M[$j][$i]"; 
		}
		print LO "\n";
    }
	
    close LO;

    print "$ans\n";
    return $ans;
}

1;
__END__

=head1 NAME

 Statistics::Gap - An adaptation of the "Gap Statistic"

=head1 SYNOPSIS

 use Statistics::Gap;
 $predictedk = &gap("prefix", "vec", INPUTMATRIX, "rbr", "h2", 30, 10, rep, 90, 4);

 OR

 use Statistics::Gap;
 $predictedk = &gap("prefix", "vec", INPUTMATRIX, "rbr", "h2", 30, 10, rep, 90, 4, 7);

=head1 INPUTS

1. Prefix: The string that should be used to as a prefix while naming the intermediate files 
and the .dat files (plot files).

2. Space: Specifies the space in which the clustering should be performed.
Valid parameter values: 
           vec  -  vector space
           sim  -  similarity space

3. InputMatrix: Path to input matrix file. (More details about the input file-format below.)

4. ClusteringMethod: Specifies the clustering method to be used. (Learn more about this at:
http://glaros.dtc.umn.edu/gkhome/cluto/cluto/overview)

    Valid parameter values:
           rb - Repeated Bisections
           rbr - Repeated Bisections for by k-way refinement
           direct - Direct k-way clustering
           agglo  - Agglomerative clustering
           bagglo - Partitional biased Agglomerative clustering
           NOTE: bagglo can be used only if space=vec

5. Crfun: Specifies the criterion function to be used for finding clustering solutions.
(Learn more about this at: http://glaros.dtc.umn.edu/gkhome/cluto/cluto/overview)

    Valid parameter values:
           i1      -  I1  Criterion function
           i2      -  I2  Criterion function
           e1      -  E1  Criterion function
           h1      -  H1  Criterion function
           h2      -  H2  Criterion function

6. K: This is an approximate upper bound for the number of clusters that may be present 
in the dataset. 

7. B: The number of replicates/references to be generated.

8. TypeRef: Specifies whether to generate B replicates from a reference or to generate 
B references.

    Valid parameter values:
           rep - replicates
           ref - references

9. Percentage: Specifies the percentage confidence to be reported in the log file.
Since Statistics::Gap uses parametric bootstrap method for reference distribution
generation, it is critical to understand the interval around the sample mean that
could contain the population ("true") mean and with what certainty.
 
10. Precision: Specifies the precision to be used while generating the reference distribution.

11. Seed: The seed to be used with the random number generator. 
(This is an optional parameter. By default no seed is set.)

=head2 Details about the input matrix format:

The input matrix can be in either dense or sparse format. The cell values can 
be integer or real. Depending upon the value specified for the space parameter 
the header in the input file (first line) changes.

Example of input matrix in dense format when space=vec:
 The first line specifies the dimensions - #rows #cols
 From the second line the actual matrix follows.

 6 5
 1.3       2       0       0       3
 2.1       0       4       2.7     0
 1.3       2       0       0       3
 2.1       0       4       2.7     0
 1.3       2       0       0       3
 2.1       0       4       2.7     0

Example of input matrix in dense format when space=sim:
 The matrix, when in similarity space, is square and symmetric. 
 The first line specifies the dimensions - #rows/#cols
 From the second line the actual matrix follows.

 5
 1.0000   0.3179   0.5544   0.2541   0.4431   
 0.3179   1.0000   0.1386   0.4599   0.5413
 0.5544   0.1386   1.0000   0.5143   0.2186
 0.2541   0.4599   0.5143   1.0000   0.5148
 0.4431   0.5413   0.2186   0.5148   1.0000

Example of input matrix in sparse format when space=vec:
 The first line specifies the dimensions & number of non-zero elements - #rows #cols #nonzeroElem

From the second line the matrix contents follow. Only non-zero elements are specified. Thus the
elements are specified as pairs of - #col elem. The row number is implied by the (line number-1).

 8 10 41
 1 3 4 2 8 2 10 1
 1 1 2 5 3 1 5 2 7 1 9 2
 1 3 4 2 8 2 10 1
 1 1 2 5 3 1 5 2 7 1 9 2
 1 3 4 2 8 2 10 1
 1 1 2 5 3 1 5 2 7 1 9 2
 2 4 3 1 4 2 5 5 7 1 9 1
 2 4 3 1 4 2 5 5 7 1 9 1

Example of input matrix in sparse format when space=sim:
 The first line specifies the dimensions & number of non-zero elements - #rows/#cols #nonzeroElem
 The matrix format is same as explained above.

 5 15
 1 1.0000 3 0.5544 5 0.4431   
 2 1.0000 3 0.1386 4 0.4599 5 0.5413
 1 0.5544 2 0.1386 3 1.0000
 2 0.4599 4 1.0000
 1 0.4431 2 0.5413 5 1.0000

=head1 OUTPUT

1. A single integer number at STDOUT which is the Gap Statistic's 
estimate of number of clusters present in the input dataset.

2. The prefix.gap.log file contains the log of various values at different K values.
The first table in the file gives values like Gap(k), obs(crfun(k)) etc. for every k value
experimented with.	

3. The prefix.*.dat files are provided to facilitate generation of plots of the observed 
distribution, expected distribution and gap(k), if desired.

=head1 DESCRIPTION

Given a dataset how does one automatically find the optimal number 
of clusters that the dataset should be grouped into? - is one of the 
prevailing problems. Statisticians Robert Tibshirani, Guenther Walther 
and Trevor Hastie  propose a solution for this problem in a Techinal 
Report named - "Estimating the number of clusters in a dataset via 
the Gap Statistic". This perl module implements an adaptation of the 
approach proposed in the above paper. 

If one tries to cluster a dataset (i.e. numerous observations described 
in terms of a feature space) into n groups/clusters and if we plot the
graph of within cluster disimilarity (error) or similarity along Y-axis 
and Number of clusters along X-axis then this graph generally takes a 
form of a elbow/knee depending upon the measure on the Y-axis. The Gap 
Statistic seeks to locate this elbow/knee because the value on the X-axis 
at this elbow is the optimal number of clusters for the data.	

To locate this elbow Gap Statistic standardizes the graph of error by
comparing it with the expected graph under appropriate null reference 
distribution. The adopted null model is the case of single cluster (k=1) 
which is rejected in favor of k (k>1) if sufficient evidence is present.
The predicted k is the k value for which the error graph falls the farthest 
below the reference graph. 

As we have seen above, the Gap Statistic uses the within cluster dispersion (error) 
measure to find the elbow/knee. In this adaptation, we use clustering criterion 
functions (crfun) instead of within cluster dispersion measure. The crfun 
are used by the clustering methods to obtain an optimal clustering solution for 
a given data and number of clusters.

We provide two types of reference generation methods: 

1. One can choose to generate a random dataset over the observed distribution by 
holding the row and the column marginals fixed and then generating B replicates 
from this random dataset using Monte Carlo sampling.
  
2. Or to generate B random datasets over the observed distribution by holding 
the row and the column marginals fixed.

Please refer to http://search.cpan.org/dist/Algorithm-RandomMatrixGeneration/ to
learn more about generating random dataset over the observed distribution by holding
the row and the column marginals fixed.

=head2 EXPORT

"gap" function by default.

=head1 PRE-REQUISITES

1. This module uses suite of C programs called CLUTO for clustering purposes. Thus CLUTO needs to be installed for this module to be functional. CLUTO can be downloaded from http://www-users.cs.umn.edu/~karypis/cluto/

2. Following Perl Modules
 Math::BigFloat (http://search.cpan.org/dist/Math-BigInt-1.77/)
 Algorithm::RandomMatrixGeneration (http://search.cpan.org/dist/Algorithm-RandomMatrixGeneration/)

=head1 SEE ALSO

    http://citeseer.ist.psu.edu/tibshirani00estimating.html
    http://www-users.cs.umn.edu/~karypis/cluto/
    http://search.cpan.org/dist/Algorithm-RandomMatrixGeneration/

=head1 AUTHOR

    Anagha Kulkarni, University of Minnesota, Duluth
    kulka020 <at> d.umn.edu
	
    Ted Pedersen, University of Minnesota, Duluth
    tpederse <at> d.umn.edu

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008, Anagha Kulkarni and Ted Pedersen

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
