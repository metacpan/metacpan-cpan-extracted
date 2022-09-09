package Optimization::NSGAII;

use 5.006;
use warnings;
use strict;

use feature 'say';
use Exporter;
our @ISA = ("Exporter");
use Data::Dumper;
use List::Util qw/min max/;
use Carp;

=pod
 
=head1 NAME

Optimization::NSGAII - non dominant sorting genetic algorithm for multi-objective optimization (also known as NSGA2)

=head1 VERSION

Version 0.02

=cut

our $VERSION = "0.02";

=head1 SYNOPSIS

	use Optimization::NSGAII qw/ f_Optim_NSGAII /;
	use Data::Dumper;

	# D E F I N E   O B J E C T I V E S   T O   O P T I M I Z E 
	###########################################################

	sub f_to_optimize {        
	    
	    my $x = shift;              # load input parameters (genes constituting a single individual)

	    # ...                       # do your things using these inputs $x->[0], $x->[1] ... 
	                                # and produce the outputs to be minimized $f1, $f2 ...

	                                # examples of things you can do include:
	                                # - mathematical formulas in perl to define $f1, $f2, ...
	                                # - computations with commercial software and so: 
	                                #       - write input file using $x->[0] ...
	                                #       - run the computation, for example with perl system() function
	                                #            - locally or
	                                #            - on a server for example with 'qsub... '
	                                #       - wait simulation to end 
	                                #       - postprocess its output and define $f1, $f2 ...
	                                # - ...
	    
	    my $out = [$f1,$f2,$f3];    # and finally return the set of these outputs for
	    return $out;                # this single individual of the population
	    
	}

	# D E F I N E   B O U N D S   [ A N D   I N E Q U A L I T I E S ]
	###################################################################
	
	                                            # define min and max bounds for $x->[0], $x->[1], ...
	my $bounds = [[0,1],[0,1],[0,1]];           # example with 3 input parameters (genes) with min = 0 and max = 1:
	
	sub f_inequality {                          # optional inequality constraints set
	
	    my $x =shift;
	    
	    my @ineq = 
	        (
	         $x->[1] + 1 ,                      # equations >= 0 
	         $x->[0] + $x->[1] - 9,
	         ...
	         ...
	                      
	        );
	        
	    return \@ineq;
	}
   
	# R U N   O P T I M I Z A T I O N
	#################################

	                                            # execute NSGA-II algorithm  

	my $ref_input_output = f_Optim_NSGAII(
	    {
	                
	        'nPop'          => 50,              # population size
	        'nGen'          => 250,             # final generation number
	        'bounds'        => $bounds,         # loads the previously defined bounds
	        'function'      => \&f_to_optimize, # loads the subroutine to optimize (minimize)
	        'nProc'         => 8,               # how many individuals to evaluate in parallel as separate processes
	        'filesDir'      => '/tmp',          # work directory
	        
	        
	        # optional parameters:
	        
	        'verboseFinal'  => 1,               # 0|1: input and output values print at final generation, for each individual of the population
	                                              # default: print is made ( = 1)
	        'f_ineq'        => \&f_inequality,  # subroutine describing the constraining inequality set
	                                              # default: no constraint function
	                                            
	                                            # parameters for mutation        
	                                                                   
	        'distrib'       => [-1,0,1],        # distribution of values (for example a Gaussian distribution), used to perturb individuals
	                                              # default: [-1,-0.5,0,0.5,1]
	        'scaleDistrib'  => 0.05,            # scaling of the distribution array
	                                              # default: 0 (no perturbation will be done)
	        'percentMut'    => 5,               # percentage of individual that are randomly perturbated (in all their genes)
	                                            # and also percentage of input parameters (genes) that are randomly mutated in each individual
	                                              # default: 5%
	        'startPop'      => [[0.3,0.18,-0.1],# initial population
	                            [-0.38,0.5,0.1],  # default: random population satisfying the bounds
	                             ...,
	                             ]

	    },

	                                            # the following is the optional set of parameters for 'Pareto front' 2D live plot
	                                            # if the part below is not present, no plot will be made

	    {

	        'dx'        => 200,                 # characters width and height of the plot
	        'dy'        => 40,
	        'xlabel'    => 'stiffness [N/mm]',  # horizontal and vertical axis labels
	        'ylabel'    => 'mass [kg]',
	        'xlim'      => [0,1],               # horizontal and vertical axis limits
	        'ylim'      => [0,1],
	        'nfun'      => [0,2],               # which function to plot from return value by f_to_optimize ($out) ; 0=f1, 1=f2 ...
	    }
	);

	# U S E   S O L U T I O N S 
	############################  

	# for example print of the input parameters and 
	# corresponding output functions' values of the final found Pareto front
	
	my @ref_input = @{$ref_input_output->[0]};
	my @ref_output = @{$ref_input_output->[1]};

	print Dumper(\@ref_input);
	print Dumper(\@ref_output);




=head1 EXPORT

=over

=item * f_Optim_NSGAII

=back

=cut

our @EXPORT_OK = qw/ f_Optim_NSGAII /;

=head1 DESCRIPTION


=head2 Reference

NSGAII.pm apply (with some variations) the NSGA-II algorithm described in the paper: 

A Fast and Elitist Multiobjective Genetic Algorithm:NSGA-II

=over 

Kalyanmoy Deb, Associate Member, IEEE, Amrit Pratap, Sameer Agarwal, and T. Meyarivan

=back


=head2 Objective

C<NSGAII.pm> performs multi-objective optimization using a genetic algorithm approach: it searches the input parameters (genes) which minimize a set of output functions and with some luck a Pareto front is produced. 
In the Pareto front no solution is better than the others because each solution is a trade-off.

=head2 Function to optimize

This module requires to define a perl subroutine (C<f_to_optimize> in the code above) which can take the input parameters and gives the corresponding outputs (in other words, it requires a subroutine to evaluate an individual of this population)


=head2 Features

The optimization is done:

=over 3

=item * considering allowed B<boundary for each input parameter (min e max)>

=item * considering optional B<set of inequality equations containing input parameters> (x1^2 + sqrt(x2) -x3 >= 0 , ...)

=item * with a B<parallel evaluation> of the subroutine to optimize (and so of individuals) in each generation, by using perl fork() function

=back 

The inequalities must be given by a subroutine which calculate the error, look below in the example: basically all the LHS of the inequalities in the form "... >=0" are put in an array.

The number of B<parallel evaluation> of C<f_to_optimize>, and so the value of C<nProc>, can be for example the max number of parallel C<f_to_optimize> computation that you want and can:

=over

=item * run on your pc if you run the computation locally (e.g. 4)

=item * run on a remote server if you run (inside the C<f_to_optimize>) the computation there (e.g. 32)

=back

C<nPop> should be multiple of C<nProc>, to optimize resources use, but it is not necessary.

Problems with this modules are expected on systems not supporting fork() perl function.

A B<2D plot> can be activated to control in real time the convergence of the algorithm on two chosen output functions (to assist at the formation of the Pareto front, generation after generation).

Each time a new generation finish, all information of the population are written in the C<filesDir> directory:

=over

=item * F<VPt_genXXXXX.txt>: input (parameters values)

=item * F<Pt_genXXXXX.txt>: output (corresponding functions values)

=back

The algorithm can start by default with a random initial population (satisfying the bounds) or the B<start population> can be assigned by assigning it to the C<startPop> option.

Assigning the population at the start can be useful for example if:

=over

=item * there was an unexpected termination of the program during the optimization, so that one can restart by using the content of one of the last saved F<VPt_genXXXXX.txt>

=item * there is the interest in continuing the optimization with different parameters

=item * there is already an idea of some input parameters which could give a good output

=back

For an example of use see F<NSGAII_startPop_example.pl>.

=head2 Mutation

The implementation of the B<mutation algorithm> part has been done in a B<different way if compared to that described in the paper>.

In particular B<two mutation> are applied in sequence:

=over

=item 1) mutation of all the input parameters (the genes), but only on a certain percentage C<percentMut> of the population: 

-> Small perturbation of the each gene by adding a number chosen randomly from the given C<distrib> (scaled with both C<scaleDistrib> and the difference between the two bounds).

=item 2) mutation of all the individuals of the population, but only on a certain percentage C<percentMut> of the input parameters (the genes)

-> Random change (inside the permitted bounds)

=back 


=head2 Verification

This module has been tested, successfully, on many of the test problems defined in the paper described in the Reference section (see EXAMPLE section)

The performance (convergence for same population number and max generation number) seems to be comparable to that described in that paper.




=head1 EXAMPLE

B<More examples> (the same test problems contained in the paper described in the Reference section) are available in the test folder (F<NSGAII_all_examples.pl> containing ZDT1, ZDT2, TNK, ...).

Here you see the B<CONSTR> problem with:

=over

=item * two input parameters $x->[0] and $x->[1]

=item * two output functions to optimize f1 and f2

=item * two constraining equations between the input parameters

=item * 8 process in parallel (8 subroutine f_CONTRS are evaluated in parallel as indipendent processes)

=back

    use Optimization::NSGAII qw/ f_Optim_NSGAII /;
    
    # function to minimize
    sub f_CONSTR {
        
        my $x = shift;
        
        my $n = scalar(@$x);
        
        my $f1 = $x->[0];
        my $f2 = (1 + $x->[1])/$x->[0];
        
        my $out = [$f1,$f2];
        
        return $out;
    }

    # inequality constraints set
    sub f_inequality {
        my $x =shift;
        
        # equation >= 0 
        my @ineq = 
            (
             $x->[1] + 9*$x->[0] - 6 ,
            -$x->[1] + 9*$x->[0] -1 
            );
            
        return \@ineq;
    }

    my $bounds = [[0.1,1],[0,5]];

    my $ref_input_output = f_Optim_NSGAII(
        {
            'nPop'          => 50,
            'nGen'          => 100,
            'bounds'        => $bounds,
            'function'      => \&f_CONSTR,
            'f_ineq'        => \&f_inequality, 
            'nProc'         => 8,
            'filesDir'      => '/tmp',
            'verboseFinal'  => 1,
            'distrib'       => [-1,-0.9,-0.8,-0.7,-0.6,-0.5,-0.4,-0.3,-0.2,-0.1,0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9],
            'scaleDistrib'  => 0.05,
            'percentMut'    => 5,
        },
        {
            'dx'            => 100,
            'dy'            => 40,
            'xlabel'        => 'stiffness [N/mm]',
            'ylabel'        => 'mass [kg]',
            'xlim'          => [0.1,1],
            'ylim'          => [0,10],
            'nfun'          => [0,1],
        }        
    );




=head1 OUTPUT PREVIEW

This below is a typical output of the final Pareto front (problem TNK).

The numbers represent the rank of the points: in the initial generations you can see points of rank 1,2,3... where points with rank 1 dominate points of rank 2 and so on.

Generation after generation all the points go on the Pareto front, so all the points become rank 1 (not dominated, nothing best is present in this population)

The points will also expand to occupy the entire front.

                            GENERATION 250
m|                                                                      
a|                                                                      
s|                                                                      
s|                                                                      
 |                                                                      
[|                                                                      
k|                                                                      
g|  1                                                                   
]|    11                                                                
 |      11                                                              
 |         1            1                                               
 |                       11                                             
 |                         1                                            
 |                          11 1   1 1 1                                
 |                                      1                               
 |                                      1                               
 |                                                                      
 |                                      1                               
 |                                      1 1                             
 |                                         1111                         
 |                                              1                       
 |                                                                      
 |                                                                      
 |                                                                      
 |                                                                      
 |                                              1                       
 |                                               11                     
 |                                                 1                    
 |                                                   1                  
 |                                                                      
 |______________________________________________________________________
                                                       stiffness [N/mm]




=head1 INSTALLATION

Following the instruction in perlmodinstall:

=over

=item * download the F<Optimization-NSGAII-X.XX.tar.gz>

=item * decompress and unpack

=over 

=item * C<gzip -d Optimization-NSGAII-X.XX.tar.gz>

=item * C<tar -xof Optimization-NSGAII-X.XX.tar>

=back

=item * C<cd Optimization-NSGAII-X.XX>

=item * C<perl Makefile.PL>

=item * C<make>
 
=item * C<make test>

=item * C<make install> 

to install it locally use this instead of C<perl Makefile.PL>:

C<perl Makefile.PL PREFIX=/my/folder> if you want to install it in /my/folder
then you will have to use in your script: C<use lib "path/before(Optimization/NSGAII.pm);"> before using C<use Optimization::NSGAII qw/ f_Optim_NSGAII /;>  

=back





=head1 AUTHOR

Dario Rubino, C<< <drubino at cpan.org> >>




=head1 BUGS

Solutions (input-output pairs) often contain duplicates, this would require some investigation.

Please report any bugs to C<bug-optimization-nsgaii at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Optimization-NSGAII>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Optimization::NSGAII


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Optimization-NSGAII>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Optimization-NSGAII>

=item * Search CPAN

L<https://metacpan.org/release/Optimization-NSGAII>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Dario Rubino.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

# A point in the population is defined by:
# - input values for the objective functions (input parameters)	-> contained in the reference VP
# - correspondent output population (objective function values) -> contained in the reference P
# 
# P is the most important set of values used in this package, because the objective functions' values lead the algorithm
# VP elements then are postprocessed accordingly so that P and VP maintain always a one to one index correspondence
#
# 					VARIABLES
#
# VP: input values for each population's point
#		: [[x11,x12,...x1D],...]
# P : population (objective values for each point)
#		: [[fun11,fun12,..fun1M],..]

# D : number of dimension of the problem (how many input values for a point)
# N : size of population P

# p,q : index of a single solution of the population
#		: id_sol_ith
# Sp: set of solution dominated by p (worse than p) for each point
#		:  [[id_sol_i,id_sol_j,...],..]

# np: number of solutions which dominate p (better than p), np = zero for first front solutions
#		: [np1,np2,..]
# F: set of solution in front ith
#		: [[id_sol_k,id_sol_t,...],...]
# rank : rank of each solution = front number , rank = 1 for first front solutions
#		: [rank1,rank2...rankN];

########################################################################################################

my @out_print;
my $inf = 1e9;

sub f_ineq2maxerr {
	# max error calculation in inequalities
	# input: lhs inequalities ref (errors)
	# output: max error
	my $ref_ineq = shift;
	
	my @ineq = @{$ref_ineq}; 
		
	my $err = 0;	
	foreach my $el(@ineq){
		$err = max( $err, -$el);
	}
	return $err;	
}


sub f_fast_non_dominated_sort {
	# reference to population
	my $P = shift;
	my $VP = shift; 
	my $f_ineq = shift;
	
		
	my $Sp;
	my $np;
	my $F;
	my $rank;
	
	my $N = scalar(@{$P});

	foreach my $p(0..$N-1){
		$np->[$p] = 0;
		foreach my $q(0..$N-1){
			next if $p == $q;                       # max error <-- inequalities <-- input pars
			if (      f_dominates($P->[$p],$P->[$q],    f_ineq2maxerr( &{$f_ineq}($VP->[$p]) ),  f_ineq2maxerr( &{$f_ineq}($VP->[$q])) )       ){
				push @{$Sp->[$p]}, $q;
			}
			elsif (   f_dominates($P->[$q],$P->[$p],    f_ineq2maxerr( &{$f_ineq}($VP->[$q]) ),  f_ineq2maxerr( &{$f_ineq}($VP->[$p])) )       ){
				$np->[$p] += 1;
			}
		}
		if ($np->[$p] == 0){
			$rank->[$p]=1; # front number, 1 = best
			push @{$F->[0]}, $p;
		}
	}
	
	# all other fronts
	my $i = 0;
	
	while (scalar(@{$F->[$i]})){
		my @Q;# members of next front
		
		foreach my $p(@{$F->[$i]}){
			foreach my $q(@{$Sp->[$p]}){
				$np->[$q] -=1;
				if ($np->[$q] == 0){
					$rank->[$q] = $i + 1 + 1;
					push @Q, $q;
				}
			}
		}
		$i++;
		$F->[$i] = [@Q];
		
	}

	for my $p(0..$N-1){
		push @out_print, join(' ',($rank->[$p],@{$P->[$p]}));
	}

	return ($rank,$F); # rank for each point, points in each front
		
}

########################################################################################################

sub f_dominates {
	# input:  two elements of P
	# output: 1 if P1 dominate P2, 0 otherwise
	
	my $P1 = shift;
	my $P2 = shift;
	
	# constraints errors
	my $err1 = shift;
	my $err2 = shift;
	

	# number of objective (dimensions)
	my $M = scalar(@{$P1});
	
	my $P1_dominate_P2_count = 0;
	
	for my $kM(0..$M-1){
		if ($P1->[$kM] <= $P2->[$kM]){
			$P1_dominate_P2_count++;
		}
	}

	my $P1_dominate_P2_p;	
	# if 1 has lower constraints errors, then 1 dominate 2, else if the error is the same (e.g 0) then the dominance is decided on objective value
	# else simply 1 doesn't dominate 2
	if  (
		$err1 < $err2 
		|| 
		($err1 == $err2 && $P1_dominate_P2_count == $M)
		){	
			$P1_dominate_P2_p = 1;
		}
	else {	$P1_dominate_P2_p = 0}
	
	return $P1_dominate_P2_p;
	
}

########################################################################################################

sub f_crowding_distance_assignment{
	# input:  ref of array of a subset of population P, population P
	# output: distance value for each point of this set

	# global ids of the set of non dominated points of interest
	my $ids = shift;
	# objectives of all points
	my $P = shift;
	
	# build the set of objectives for these global ids (I is a subset of P)
	my $I = [@{$P}[@{$ids}]];
	
	# initialize distance
	my $Dist;
	
	# number of objective (dimensions)
	my $M = scalar(@{$P->[0]});
	# number of points in I
	my $n = scalar(@{$ids});
	
	# for each objective
	for my $kM(0..$M-1){

		# local id of the points, sorted by objective
		my @index_sort = sort{$I->[$a][$kM] <=> $I->[$b][$kM]} 0..($n-1);

		# min & max for this objective
		my $fmin = $I->[$index_sort[0]][$kM];
		my $fmax = $I->[$index_sort[-1]][$kM];
		
		if ($fmax-$fmin<0.00001){$fmax += 0.00001}

		# build the distance
		$Dist->[$index_sort[0]] = $inf;
		$Dist->[$index_sort[-1]] = $inf;
		# and for all other intermediate point
		for my $i(1..($n-2)){
			$Dist->[$index_sort[$i]] += ($I->[$index_sort[$i+1]][$kM] - $I->[$index_sort[$i-1]][$kM])/($fmax-$fmin);
		}
		
	}
	# return distances for each point, $Dist->[ith] is distance for point $ids->[ith]
	return $Dist;
}

########################################################################################################

sub f_crowding_distance_operator {
	# input: rank and distance of two element of the population (selected by GA)
	# output: 1 if first dominate second, else 0
	
	my $rank = shift;
	my $Dist = shift;
	
	my $P1_dominate_P2_p;
	
	if (
		$rank->[0] < $rank->[1] 
		|| 
		($rank->[0] == $rank->[1]) && ($Dist->[0] > $Dist->[1])
		){
			$P1_dominate_P2_p = 1
		}
	else {$P1_dominate_P2_p = 0}
	return $P1_dominate_P2_p;
}

########################################################################################################

sub f_NSGAII {
	# input:  current function input values VP(t) & VQ(t) ( VQ is obtained by GA)
	#		  current population Pt & Qt (obtained by evaluating objective function using VPt & VQt)
	# output: VP(t+1), P(t+1), rank & distance for each point of this new population
	
	# input variables' values
	my $VPt = shift;
	my $VQt = shift;
	
	# population (objective function values)
	my $Pt = shift;
	my $Qt = shift;
	
	# constraints function
	my $f_ineq = shift;
	
	my $Rt = [(@$Pt,@$Qt)];
	my $VRt = [(@$VPt,@$VQt)];
	my $N = scalar(@$Pt);
	
	my ($temp,$F) = f_fast_non_dominated_sort($Rt,$VRt,$f_ineq);
	
	# input variables for the new population P_t+1
	my $VPtp1=[];
	# new population
	my $Ptp1=[];
	my $Dist=[];
	my $rank=[];
	
	my $i=0;
	# push the best fronts in final population & store crowding distance
	while ( scalar(@{$Ptp1}) + scalar(@{$F->[$i]}) <= $N ){
		push @$Ptp1, @$Rt[@{$F->[$i]}];
		push @$VPtp1,@$VRt[@{$F->[$i]}];
		my $Dist_ = f_crowding_distance_assignment($F->[$i],$Rt);
		push @$rank, ($i+1) x @$Dist_;
		push @$Dist, @$Dist_;
		$i++;
	}

	# only part of the following front will be pushed in final population, sorting by crowding
	# here rank is the same for all points, so the crowded-comparison operators reduce to a comparison of crowding distance
	my $Dist_ = f_crowding_distance_assignment($F->[$i],$Rt);

	my $nf = scalar(@{$F->[$i]});
	
	my @index_sort = sort{$Dist_->[$b] <=> $Dist_->[$a]} 0..($nf-1);
	
	# cut to fill only the remaining part of Ptp1
	@index_sort = @index_sort[0..(($N-scalar(@$Ptp1))-1)];

	push @$Ptp1, @$Rt[@{$F->[$i]}[@index_sort]];
	push @$VPtp1, @$VRt[@{$F->[$i]}[@index_sort]];
	push @$rank, ($i+1) x @index_sort;
	push @$Dist, @$Dist_[@index_sort];


	return $VPtp1,$Ptp1,$rank,$Dist;

}

########################################################################################################

sub f_SBX {
	my $contiguity = shift; # >0 (usually between 2 and 5), greater value produces child values similar to those of the parents
	my $VP1_ = shift; # input values of parent 1 (ref)
	my $VP2_ = shift; # input values of parent 2 (ref)
	
	# array of equal length
	my @VP1 = @$VP1_;
	my @VP2 = @$VP2_;
	my @out;
	
	for my $kp(0..$#VP1){
		# for array of length=1 or rand<0.5 the cross is made
		if ( $#VP1 == 0 || rand(1)<0.5){
			
			my $u = rand(1);
			
			my $exponent = (1/($contiguity+1));
			my $beta = ($u < 0.5)? (2*$u)**$exponent : (0.5/(1-$u))**$exponent;
			
			my $sign = (rand(1) < 0.5)? -1 : 1;
			$out[$kp] = (($VP1[$kp] + $VP2[$kp])/2) + $sign * $beta*0.5*abs($VP1[$kp] - $VP2[$kp])
			
		}
		else {
			$out[$kp] = $VP1[$kp]
		}
	}
	return \@out;
}

########################################################################################################

sub f_GA  {
	# input: input values, rank and Dist of the population P(t+1)
	# output: input value of the population Q(t+1)
	
	my $VPtp1 = shift;
	my $rank = shift;
	my $Dist = shift;
	my $contiguity = shift;
	
	my $bounds = shift; # for mutation
	
	# optional paramters for mutation:
	my $distrib = shift; 
	my $scaleDistrib = shift; 
	my $percentMut =shift;
	
	my $VQtp1 = [];
	
	# binary tournament 
	# two random element are compared
	# the best according crowding distance operator is selected as parent 1
	# the same for selecting parent 2
	# parent 1 and 2 are crossed with SBX to give a child
	# the procedure is repeated to fill Q(t+1)
	
	my $N = scalar(@$VPtp1);
	
	for my $kt(0..$N-1){

		# selection of the two parent
		my @index_parent;
		for (1..2){
			my ($r1,$r2) = (int(rand($N)),int(rand($N)));
			my $P1_dominate_P2_p = f_crowding_distance_operator( [$rank->[$r1],$rank->[$r2]] , [$Dist->[$r1],$Dist->[$r2]] );
			
			if ($P1_dominate_P2_p == 1){push @index_parent, $r1}
			else {push @index_parent, $r2}
		}
		# crossover of the two parent
		my $out = f_SBX( $contiguity , $VPtp1->[$index_parent[0]] , $VPtp1->[$index_parent[1]] );
		push @$VQtp1, $out;
	}
		
	# mutation 1
	# perturbation using distribution array
	for my $k(0..(scalar(@$VQtp1) - 1)){
		# $percentMut percentage of individuals are changed in all their elements (all input parameter will be perturbated)
		if (rand(1)> 1-$percentMut/100){
			for my $d(0..(scalar(@{$VQtp1->[0]}) - 1)){
				# increment the current value by a random value chosen from the distribution (many time it will be near to zero for a gaussian distribution) scaled with the delta_bounds
				$VQtp1->[$k][$d] += ($bounds->[$d][1] - $bounds->[$d][0]) * $scaleDistrib * $distrib->[int(rand(scalar(@$distrib)))];
			}
		}
	}
	
	# mutation 2
	# 100% probability of mutation inside VQ(t+1), so the intention is to act on all individual of the population
	for my $k(0..int((scalar(@$VQtp1) - 1) * 100/100)){
		for my $d(0..(scalar(@{$VQtp1->[0]}) - 1)){
			# $percentMut percentage of values are changed inside each single individual, value is inside bounds					
			if (rand(1)> 1-$percentMut/100){
				$VQtp1->[$k][$d] = rand(1) * ($bounds->[$d][1] - $bounds->[$d][0]) + $bounds->[$d][0];
			}
		}
	}		

	return $VQtp1;	

}



sub f_Optim_NSGAII {

	my $par = shift;
	
	my $par_plot = shift;
	
	
	
	my %par = %{$par};

	my $nPop = $par{'nPop'};
	my $nGen = $par{'nGen'};

	my $bounds = $par{'bounds'};
	my $n = scalar @$bounds;
	
	my $fun = $par{'function'};
	
	# optional paramters:
	
	my $f_ineq = $par{'f_ineq'} // sub {return [0]};	

	my $verboseFinal = $par{'verboseFinal'} // 1;

	my $distrib = $par{'distrib'} // [-1,-0.5,0,0.5,1]; # for mutation, default [-1,-0.5,0,0.5,1]
	my $scaleDistrib = $par{'scaleDistrib'} // 0;       # for mutation, default = 0, no perturbation
	my $percentMut = $par{'percentMut'} // 5;           # for mutation, default = 5%
	
    my $startPop = $par{'startPop'} //  'nostartPop';

	# control for no wrong use of keys
	my @keys_ok = ('nPop','nGen','bounds','function','nProc','filesDir','verboseFinal','f_ineq','distrib','scaleDistrib','percentMut','startPop');
	for my $key(keys %par){
		unless ( grep( /^$key$/, @keys_ok ) ) {
		  die 'E R R O R : the use of "'.$key.'" in the function to optimize is not defined! Compare with documentation.';
		}
	}
	
	my $VPt;
	my $VQt;


    for my $gen(0..$nGen){
	    if ($gen == 0){
		    # input
		    for (0..$nPop-1){
                    if ($startPop eq 'nostartPop'){
    				    $VPt->[$_]=[map { rand(1) * ($bounds->[$_-1][1] - $bounds->[$_-1][0]) + $bounds->[$_-1][0] } 1..$n];
                    }
                    else {
                        $VPt = $startPop;
                    }
				    $VQt->[$_]=[map { rand(1) * ($bounds->[$_-1][1] - $bounds->[$_-1][0]) + $bounds->[$_-1][0] } 1..$n];
			    }
	    }








		my $nProc = $par{'nProc'};
		my $filesDir = $par{'filesDir'};

		# if ($nPop%$nProc != 0){warn "\n nPop should be divisible by nProc!\n\n"};

		my $fork = 0;

		for (1..$nProc){

			my $pid = fork;
			die $! unless defined $pid;
			$fork++;
			
			# say "in PID = $$ with child PID = $pid fork# = $fork";
			# parent process stop here, child processes go on
			next if $pid;
				
			my $r = 0;
			
			my $nameFileP = $filesDir.'/Pt_'.$fork.'.txt';
			my $nameFileQ = $filesDir.'/Qt_'.$fork.'.txt';
			
			# remove existing input file for this process number
			system ('rm -f '.$nameFileP);
			system ('rm -f '.$nameFileQ);
			
	
			my $id_from = ($fork-1)*int($nPop/$nProc);
			my $id_to   = $fork    *int($nPop/$nProc)-1;
			if ($fork == $nProc){$id_to = $nPop - 1};
			
			# output
			open my $fileoP, '>>', $nameFileP or croak "E R R O R : problem in writing the file ".$nameFileP.' -> "filesDir" path not reachable? -- ';
			open my $fileoQ, '>>', $nameFileQ or croak "E R R O R : problem in writing the file ".$nameFileQ.' -> "filesDir" path not reachable? -- ';
			for ($id_from .. $id_to){
				my $Pt_ = &{$fun}($VPt->[$_]);
				my $Qt_ = &{$fun}($VQt->[$_]);
				say $fileoP join ',',@{$Pt_};
				say $fileoQ join ',',@{$Qt_};
			}
			close $fileoP;
			close $fileoQ;
			exit;
		}

		# wait for the processes to finish
		my $kid;
		do {
			$kid = waitpid -1, 0;
		} while ($kid>0);

		my $Pt;
		my $Qt;
	
		# collect data together
		for (1..$nProc){
			
			my $nameFileP = $filesDir.'/Pt_'.$_.'.txt';
			my $nameFileQ = $filesDir.'/Qt_'.$_.'.txt';
			open my $fileiP, '<', $nameFileP or croak "E R R O R : problem in reading the file ".$nameFileP.' -> "filesDir" path not reachable? ';
			open my $fileiQ, '<', $nameFileQ or croak "E R R O R : problem in reading the file ".$nameFileQ.' -> "filesDir" path not reachable? ';
			
			while (my $line = <$fileiP>){
				chomp $line;
				my @vals = split ',', $line;
				push @$Pt, \@vals;
			}			
			while (my $line = <$fileiQ>){
				chomp $line;				
				my @vals = split ',', $line;
				push @$Qt, \@vals;
			}			
			close $fileiP;
			close $fileiQ;
		}

		
		
		# new input
		my ($VPtp1,$Ptp1,$rank,$Dist)=f_NSGAII($VPt,$VQt,$Pt,$Qt,$f_ineq);

		# save inputs and corresponding outputs at this generation
		my $to_print;
		my $FILEO;
		# inputs (genes for each individual)
		open $FILEO, '>', $filesDir.'/VPt_gen'.sprintf('%05d',$gen).'.txt' or croak 'E R R O R : problem in writing the generation file -> "filesDir" path not reachable? ';
			$to_print = f_print_columns($VPt,'%25.15f');
			print $FILEO (join "\n", @$to_print);
		close $FILEO;	
		# outputs (f1, f2 ... for each individual)
		open $FILEO, '>', $filesDir.'/Pt_gen'.sprintf('%05d',$gen).'.txt' or croak 'E R R O R : problem in writing the generation file -> "filesDir" path not reachable? ';
			$to_print = f_print_columns($Pt,'%25.15f');
			print $FILEO (join "\n", @$to_print);
		close $FILEO;			

		
		#print " example input values: " ;
		#say join ' ', @{$VPtp1->[0]};
		
		if (defined $par_plot){
			f_plot($par_plot,$gen,$Ptp1,$rank);
			say '';

			my $max = -$inf;
			my $min = $inf;
			
			for (0..$nPop-1){
				$max = max(@{$Pt->[$_]},@{$Qt->[$_]},$max);
				$min = min(@{$Pt->[$_]},@{$Qt->[$_]},$min);
			}
			say 'max output = '.$max;
			say 'min output = '.$min;


			my $maxV = -$inf;
			my $minV= $inf;
			
			my $minD = min(@$Dist);
			

			for (0..$nPop-1){
				
				$maxV = max(@{$VPt->[$_]},@{$VQt->[$_]},$maxV);
				$minV = min(@{$VPt->[$_]},@{$VQt->[$_]},$minV);
				
			}
			say 'max input = '.$maxV;
			say 'min input = '.$minV;
			
			say 'min Dist = '.$minD;
		}


		my ($VQtp1) = f_GA($VPtp1,$rank,$Dist,2.0,$bounds,$distrib,$scaleDistrib,$percentMut);

		# correction of input values produced by GA to respect bounds
		for my $p(0..$nPop-1){
			for my $d(0..$n-1){
				if($VQtp1->[$p][$d] < $bounds->[$d][0]){$VQtp1->[$p][$d] = $bounds->[$d][0]};
				if($VQtp1->[$p][$d] > $bounds->[$d][1]){$VQtp1->[$p][$d] = $bounds->[$d][1]};
			}
		}

		# new output
		my $Qtp1;
		for (0..$nPop-1){
			$Qtp1->[$_]=&{$fun}($VQtp1->[$_]);
			}
			
		# new became old
		$VPt = [@$VPtp1];	
		$VQt = [@$VQtp1];
		
		
		# output final	
		if($gen == $nGen){
			if ($verboseFinal == 1){
				say '------------------------- I N P U T -------------------------:';
				map {say join ' ',@{$_}} @$VPt;
				say '------------------------- O U T P U T -------------------------';
				map {say join ' ',@{$_}} @$Pt;
			}
			
			return [$VPt,$Pt];
			
		}		
		
	}
		
}



sub f_print_columns {
	# to print in columns format the content of $P, $Ptp1 ...
	my $P = shift;
	my $formato = shift; # e.g. '%25.15f'
	
	# how many input parameters (genes)
	my $n = scalar @{$P->[0]};
	# population number
	my $nPop = scalar @$P;
	
	# print, each line contains the genes of an individual
	my @to_print;
	for my $kl(0..($nPop-1)){
		my $line;
		for my $kx(0..($n-1)){
			$line.= sprintf($formato,$P->[$kl][$kx]) . ' ';
		}
		push @to_print, $line;
	}
	
	return \@to_print;
}

########################################################################################################

sub f_plot {
    my $par_ref = shift;
    
    my $gen = shift;

    my $P = shift;
    my $rank = shift;    
    
    
    
    
    my %par = %{$par_ref};
	
	# nfun: what objective to plot from all (x=f1 y=f4 -> [0,3])
	my $nfun = $par{'nfun'};

    
    my $title = 'GENERATION '.$gen;

	# inizialization of all lines of output
    my @output = map{ ' ' x $par{'dx'} } 1..$par{'dy'};
    
    my @nameFront =(0..9,"a".."z","A".."Z");
    
	# print points of the front
	my $xASCIImin = 0;
	my $xASCIImax = $par{'dx'}-1;
	my $yASCIImin = $par{'dy'}-1;
	my $yASCIImax = 0;	
	my $n_outliers = 0;	
	
	for my $kp(1..scalar(@{$P})-1){
		# conversion x,y -> xASCII,yASCII
		my $x = $P->[$kp][$nfun->[0]];
		my $y = $P->[$kp][$nfun->[1]];
		my $xmin = $par{'xlim'}->[0];
		my $xmax = $par{'xlim'}->[1];
		my $ymin = $par{'ylim'}->[0];
		my $ymax = $par{'ylim'}->[1];	
		
		my $xASCII;
		my $yASCII;

		
		if ($x < $xmax && $x > $xmin && $y < $ymax && $y > $ymin && $rank->[$kp] < $#nameFront){
			$xASCII = f_interp($xmin,$xmax,$xASCIImin,$xASCIImax,$x);
			$yASCII = f_interp($ymin,$ymax,$yASCIImin,$yASCIImax,$y);

			substr($output[$yASCII],$xASCII,1,$nameFront[$rank->[$kp]]);
			
		}
		else {$n_outliers++};
	}
	
	# add axis
	push @output, '_' x $par{'dx'};
	@output = map{'|'.$_} @output;
	# add axis labels
    push @output, sprintf("%$par{'dx'}s",$par{'xlabel'});
    my @ylabelv = split '',$par{'ylabel'};
	@output = map{ defined $ylabelv[$_] ? $ylabelv[$_].$output[$_] : ' '.$output[$_]} 0..$#output;
	# add statistics
	unshift @output, sprintf("%".int(($par{'dx'}+length($title))/2)."s",$title);
	push @output, "xlim: ".(join ' ',@{$par{'xlim'}});
	push @output, "ylim: ".(join ' ',@{$par{'ylim'}});
	push @output, "#outliers: ".$n_outliers;
	
	print join "\n", @output;    
	
}


sub f_interp{
	my ($xmin,$xmax,$xASCIImin,$xASCIImax,$x) = @_;
	my $xASCII = ($xASCIImax-$xASCIImin)/($xmax-$xmin)*($x-$xmin)+$xASCIImin;
	$xASCII = sprintf("%.0f",$xASCII);
	return $xASCII
}






1;
