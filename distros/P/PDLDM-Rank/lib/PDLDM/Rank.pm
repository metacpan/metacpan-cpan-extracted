package PDLDM::Rank;

use 5.0;
use strict;
use warnings;
require Exporter;

use vars qw($VERSION);
$VERSION = 2015.071601;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(TiedRank EstimateTiedRank EstimateTiedRankWithDups UniqueRank EstimateUniqueRankWithDups) ;

use PDL;

sub EstimateTiedRank{#Estimate the tied rank of an unseen instance    
    my $insts =  $_[0]; #Unseen instances
    my $mypdl =  $_[1]; #Original Dataset of which Tied Ranks are already calculated
    my $ranked_pdl =  $_[2]; # Tied Ranked dataset of $mypdl
    
    my $rows = $mypdl->getdim(0);
    my $cols = $mypdl->getdim(1);
    
    my $insts_rows = $insts->getdim(0);
    
    my $inst_ranked = PDL->zeros($insts_rows,$cols) -1;
    my $inst_uniqueness = PDL->ones($insts_rows,$cols);
    
    
    for (my $this_col=0; $this_col < $cols; $this_col++){
	    my $original_values = $mypdl->dice_axis(1,$this_col)->flat;
	    my $sorted_indx = qsorti($original_values);
	    my $sorted_values = $original_values->dice($sorted_indx);
	    
        for (my $this_inst_raw=0; $this_inst_raw < $insts_rows; $this_inst_raw++){		
	    my $this_value = $insts->dice($this_inst_raw,$this_col)->flat;	    
	    
	    for (my $i = 0; $i < $rows; $i++){
		my $sorted_val = $sorted_values->dice($i)->flat;
		if ($this_value == $sorted_val) {
		    SetValue($inst_ranked->dice($this_inst_raw,$this_col),
                             $ranked_pdl->dice($sorted_indx->dice($i),$this_col));
                    SetValue($inst_uniqueness->dice($this_inst_raw,$this_col),0,0);
		    last;
		}elsif ($this_value < $sorted_val) {		    
		    SetValue($inst_ranked->dice($this_inst_raw,$this_col),$i);
		    last;
		}		
	    }
	    if ($inst_ranked->dice($this_inst_raw,$this_col) == -1) {
		SetValue($inst_ranked->dice($this_inst_raw,$this_col),$rows);
	    }
	    	    
	}
    }
    
    return ($inst_ranked,$inst_uniqueness);    
}

sub EstimateUniqueRankWithDups{#Estimate the tied rank of an unseen instance    
    my $insts =  $_[0]; #Unseen instances
    my $mypdl =  $_[1]; #Original Dataset of which Tied Ranks are already calculated
    my $ranked_pdl =  $_[2]; # Tied Ranked dataset of $mypdl
    my $duplicates_pdl =  $_[3]; # Number of duplicates in the tied Ranked dataset of $mypdl
    
    my $rows = $mypdl->getdim(0);
    my $cols = $mypdl->getdim(1);
    
    my $insts_rows = $insts->getdim(0);
    
    my $inst_ranked = PDL->zeros($insts_rows,$cols) -1;
    my $inst_duplicates = PDL->zeros($insts_rows,$cols);
    
    
    for (my $this_col=0; $this_col < $cols; $this_col++){
	    my $original_values = $mypdl->dice_axis(1,$this_col)->flat;
	    my $sorted_indx = qsorti($original_values);
	    my $sorted_values = $original_values->dice($sorted_indx);
	    
        for (my $this_inst_raw=0; $this_inst_raw < $insts_rows; $this_inst_raw++){		
            my $this_value = $insts->dice($this_inst_raw,$this_col)->flat;	    
            
            for (my $i = 0; $i < $rows; $i++){
                my $sorted_val = $sorted_values->dice($i)->flat;
                if ($this_value == $sorted_val) {
                    SetValue($inst_ranked->dice($this_inst_raw,$this_col),
                                     $ranked_pdl->dice($sorted_indx->dice($i),$this_col));
                    SetValue($inst_duplicates->dice($this_inst_raw,$this_col),
                                    $duplicates_pdl->dice($sorted_indx->dice($i),$this_col));                            
                    last;
                }elsif ($this_value < $sorted_val) {
                    if ($i > 0) {
                        SetValue($inst_ranked->dice($this_inst_raw,$this_col),
                             $ranked_pdl->dice($sorted_indx->dice($i-1),$this_col));
                        last;
                    }else{
                        SetValue($inst_ranked->dice($this_inst_raw,$this_col),0);
                        last;
                    } 
                }
            }
            if ($inst_ranked->dice($this_inst_raw,$this_col) == -1) {
                SetValue($inst_ranked->dice($this_inst_raw,$this_col),$ranked_pdl->dice($sorted_indx->dice($rows-1),$this_col));
            }
	    	    
        }
    }
    
    return ($inst_ranked,$inst_duplicates);    
}

sub EstimateTiedRankWithDups{#Estimate the tied rank of an unseen instance    
    my $insts =  $_[0]; #Unseen instances
    my $mypdl =  $_[1]; #Original Dataset of which Tied Ranks are already calculated
    my $ranked_pdl =  $_[2]; # Tied Ranked dataset of $mypdl
    my $duplicates_pdl =  $_[3]; # Number of duplicates in the tied Ranked dataset of $mypdl
    
    my $rows = $mypdl->getdim(0);
    my $cols = $mypdl->getdim(1);
    
    my $insts_rows = $insts->getdim(0);
    
    my $inst_ranked = PDL->zeros($insts_rows,$cols) -1;
    my $inst_duplicates = PDL->zeros($insts_rows,$cols);
    
    
    for (my $this_col=0; $this_col < $cols; $this_col++){
	    my $original_values = $mypdl->dice_axis(1,$this_col)->flat;
	    my $sorted_indx = qsorti($original_values);
	    my $sorted_values = $original_values->dice($sorted_indx);
	    
        for (my $this_inst_raw=0; $this_inst_raw < $insts_rows; $this_inst_raw++){		
	    my $this_value = $insts->dice($this_inst_raw,$this_col)->flat;	    
	    
	    for (my $i = 0; $i < $rows; $i++){
		my $sorted_val = $sorted_values->dice($i)->flat;
		if ($this_value == $sorted_val) {
		    SetValue($inst_ranked->dice($this_inst_raw,$this_col),
                             $ranked_pdl->dice($sorted_indx->dice($i),$this_col));
            SetValue($inst_duplicates->dice($this_inst_raw,$this_col),
                            $duplicates_pdl->dice($sorted_indx->dice($i),$this_col));                            
		    last;
		}elsif ($this_value < $sorted_val) {		    
		    SetValue($inst_ranked->dice($this_inst_raw,$this_col),$i);
		    last;
		}		
	    }
	    if ($inst_ranked->dice($this_inst_raw,$this_col) == -1) {
		SetValue($inst_ranked->dice($this_inst_raw,$this_col),$rows);
	    }
	    	    
	}
    }
    
    return ($inst_ranked,$inst_duplicates);    
}

sub TiedRank{    #Calculate Tied Ranks
    my $mypdl =  $_[0];
    my $rows = $mypdl->getdim(0);
    my $cols = $mypdl->getdim(1);
    my $ranked_pdl = PDL->zeros($rows,$cols);
    my $duplicates_pdl = PDL->zeros($rows,$cols);

    for (my $this_col=0; $this_col < $cols; $this_col++){	
	my $sorted_indx = qsorti($mypdl->dice_axis(1,$this_col)->flat);
	my $last_ranked_indx = -1;
	my $last_rank = 0;
	my $last_value = $mypdl->dice($sorted_indx->dice(0),$this_col);
	my $duplicate_count = 1;
	
	for (my $i=1; $i <= $rows; $i++){
	    my $this_value = 0;
	    if ($i < $rows) {
		$this_value =$mypdl->dice($sorted_indx->dice($i),$this_col);
	    }
	    if (($this_value > $last_value) || ($i == $rows)) {
		my $average_rank =  ((2 * $last_rank) + $duplicate_count + 1) / 2;
		#my $ranked_slice = PDL->ones($duplicate_count,1) * $average_rank;
		my $rank_start_indx = $last_ranked_indx + 1;
		$last_ranked_indx = $last_ranked_indx + $duplicate_count;
		
		for (my $tmp_rank_indx=$rank_start_indx;$tmp_rank_indx <= $last_ranked_indx; $tmp_rank_indx++){
		    my $tmp_correct_indx = sclr $sorted_indx->dice($tmp_rank_indx);
		    SetValue($ranked_pdl->slice("($tmp_correct_indx),($this_col)"),$average_rank);
                    SetValue($duplicates_pdl->slice("($tmp_correct_indx),($this_col)"),$duplicate_count);
		}
		
		$duplicate_count = 1;
		$last_value = $this_value;
		$last_rank = $i;
	    }else{
		$duplicate_count++;
	    }
	}
    }
    return ($ranked_pdl,$duplicates_pdl);
}

sub UniqueRank{    #Calculate Unique Ranks
    my $mypdl =  $_[0];
    my $rows = $mypdl->getdim(0);
    my $cols = $mypdl->getdim(1);
    my $ranked_pdl = PDL->zeros($rows,$cols);
    my $duplicates_pdl = PDL->zeros($rows,$cols);

    for (my $this_col=0; $this_col < $cols; $this_col++){	
	my $sorted_indx = qsorti($mypdl->dice_axis(1,$this_col)->flat);
	my $last_ranked_indx = -1;
	my $last_rank = 0;
	my $last_value = $mypdl->dice($sorted_indx->dice(0),$this_col);
	my $duplicate_count = 1;
	
	for (my $i=1; $i <= $rows; $i++){
	    my $this_value = 0;
	    if ($i < $rows) {
            $this_value =$mypdl->dice($sorted_indx->dice($i),$this_col);
	    }
	    if (($this_value > $last_value) || ($i == $rows)) {
            my $this_rank =  $last_rank + 1;
            #my $ranked_slice = PDL->ones($duplicate_count,1) * $average_rank;
            my $rank_start_indx = $last_ranked_indx + 1;
            $last_ranked_indx = $last_ranked_indx + $duplicate_count;
            
            for (my $tmp_rank_indx=$rank_start_indx;$tmp_rank_indx <= $last_ranked_indx; $tmp_rank_indx++){
                my $tmp_correct_indx = sclr $sorted_indx->dice($tmp_rank_indx);
                SetValue($ranked_pdl->slice("($tmp_correct_indx),($this_col)"),$this_rank);
                SetValue($duplicates_pdl->slice("($tmp_correct_indx),($this_col)"),$duplicate_count);
            }
            
            $duplicate_count = 1;
            $last_value = $this_value;
            $last_rank = $this_rank;
	    }else{
            $duplicate_count++;
	    }
	}
    }
    return ($ranked_pdl,$duplicates_pdl);
}

sub SetValue{
    my $this_slice = $_[0];
    my $new_values = $_[1];
    my $ops = $_[2]; #0 = Substitute, 1 = add, 2= substract
    
    if (!(defined($ops))) {
	$ops = 0;
    }
    
    if ($ops == 0) {
        $this_slice .= $new_values;
    }elsif($ops == 1){
        $this_slice += $new_values;
    }elsif($ops == 2){
        $this_slice -= $new_values;
    }
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PDLDM::Rank - Calculates and finds tied ranks of a PDL data matrix

=head1 SYNOPSIS

    use PDL;
    use PDLDM::Rank qw(TiedRank EstimateTiedRank EstimateTiedRankWithDups UniqueRank EstimateUniqueRankWithDups );
    
    my $training_pdl = pdl ([[1,2,3,3,4,4,4,5,6,6], [1,1,1,2,2,4,4,5,6,6]]);
    print "training data $training_pdl";
    my ($ranked_training_pdl,$duplicates_training_pdl) = TiedRank($training_pdl);
    print "ranked training data $ranked_training_pdl";
    print "duplicate count in the training data $duplicates_training_pdl";
    
    my $test_pdl = pdl ([[0.5,4,4.5,6.5], [0.2,1,2,2.5]]);
    print "test data $test_pdl";
    my ($ranked_test_pdl,$unique_test_pdl) = EstimateTiedRank($test_pdl,$training_pdl,$ranked_training_pdl);
    
    print "ranked test data $ranked_test_pdl";
    print "is the value unique?  $unique_test_pdl";
    
    my ($ranked_dup_test_pdl,$dup_test_pdl) = EstimateTiedRankWithDups($test_pdl,$training_pdl,$ranked_training_pdl,$duplicates_training_pdl);
    
    print "ranked test data $ranked_dup_test_pdl";
    print "number of duplicates in the training data  $dup_test_pdl";
    
    my ($uranked_training_pdl,$urank_training_dup_pdl) = UniqueRank($training_pdl);
    print "Unique ranked training data $uranked_training_pdl";
    print "duplicate count in the training data $urank_training_dup_pdl";
    
    my ($uranked_dup_test_pdl,$udup_test_pdl) = EstimateUniqueRankWithDups($test_pdl,$training_pdl,$uranked_training_pdl,$urank_training_dup_pdl);        
    print "Unique ranked test data $uranked_dup_test_pdl";
    print "number of duplicates in the training data  $udup_test_pdl";

    
=head1 DESCRIPTION

PDLDM::Rank finds the tied rank values of a given PDL.
In the data PDL, the raws should represent the data instances and colomns should represent the attributes.

TiedRank

This returns two PDLs each with the same size as the imput PDL.
The first variable contains the tied rank values.
The second variable contains the number of instances that share the same value.
TiedRank function should produce the same results as the MATLAB tiedrank function.

EstimateTiedRank

In some cases data are divided into two parts, training and testing (or evaluation).
Tied ranks are first evaluated for the training data.
It may be ineffient to re-evaluate the tied ranks of both training and testing data together.

EstimateTiedRank finds the lowest nearest rank for the test data.
It needs three PDL inputs: test data, training data and tied ranks of the training data respectively.
Tied ranks of the training data is the first variable retuned by the TiedRank function.

EstimateTiedRank returns two PDL varibles each of the same size as the test data PDL.
The first varible contains the lowest nearest ranks from the tied ranks of the training data.
The second variable contains whether the value is unique, ie. to be unique it should not exist in the training dataset in the corresponding attribute.

EstimateTiedRankWithDups

This produces similar functionality to the EstimateTiedRank.
However additionally it needs number of duplicates as returned by TiedRank.
It retunes the duplicate count in the traning data instead of the uniqueness.
Therefore, if a value in the second retuned parameter (duplicate count) is zero, the corresponding value in the test/evaluation data is unique.

UniqueRank
This function works with similar input and output parameters as the TiedRank function.
However, it produces ranking without leaving gaps for duplicates.
For example, [ 1 4 4 6 8 8 8 9] given [1 2 2 3 4 4 4 5] ranks.

EstimateUniqueRankWithDups

This performs a similar fucntion as EstimateTiedRankWithDups, but with the data from the UniqueRank function.


DEPENDENCIES

This module requires these other modules and libraries:

PDL

=head1 SEE ALSO

Please refer http://pdl.perl.org/ for PDL.
PDL is very efficeint in terms of memory and execution time.

=head1 AUTHOR

Muthuthanthiri B Thilak Laksiri Fernando 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Muthuthanthiri B Thilak L Fernando

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


