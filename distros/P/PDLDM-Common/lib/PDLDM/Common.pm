package PDLDM::Common;

use 5.0;
use strict;
use warnings;
require Exporter;

use vars qw($VERSION);
$VERSION = 2015.071403;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(NormalizeData WritePDL2DtoCSV ReadCSVtoPDL WritePDL3DtoCSV WritePDL3DtoCSV SetValue GetSampleWithoutReplacements);

use PDL;
use Math::Random::MT::Auto qw(rand shuffle);
use Text::CSV;

sub NormalizeData{    
    my $data =  $_[0];    
    my $rows = $data->getdim(0);
    my $cols = $data->getdim(1);
    for (my $this_col=0; $this_col < $cols; $this_col++){
	my $this_raw = $data->slice(":,($this_col)");
	my $min_data = transpose(minimum($this_raw));
	my $max_data = transpose(maximum($this_raw));
	if (abs($min_data - $max_data) > 0) {
	    $this_raw .= ($this_raw - $min_data) / ($max_data - $min_data);	    
	}	
    }    
}

sub WritePDL2DtoCSV{    
    my $mypdl =  $_[0];
    my $csv_file =  $_[1];
    
    unlink($csv_file);
    open FF, ">" .  $csv_file ;
    my $rows = $mypdl->getdim(0);
    for (my $r = 0; $r < $rows; $r++){
	print FF join(",",@{unpdl $mypdl->slice("($r),:")}) ;
	print FF "\n";
    }    
    close FF;

}

sub ReadCSVtoPDL{        
    my $csv_file =  $_[0];    
    open my $fh, "<", $csv_file;
    my @CSVData;
    my $csv = Text::CSV->new();
    while ( my $row = $csv->getline( $fh ) ) {	      
        push @CSVData, $row;          
    }
    return transpose(pdl(@CSVData));
}

sub WritePDL3DtoCSV{    
    my $mypdl =  $_[0];
    my $csv_file =  $_[1];
    
    unlink($csv_file);
    open FF, ">" .  $csv_file ;
    my $d1rows = $mypdl->getdim(0);
    my $d2rows = $mypdl->getdim(1);
    print FF  join(",",@{unpdl $mypdl->shape}) . "\n" ;
    for (my $d1r = 0; $d1r < $d1rows; $d1r++){
	for (my $d2r = 0; $d2r < $d2rows; $d2r++){
	    print FF join(",",@{unpdl $mypdl->slice("($d1r),($d2r),:")}) ;
	    print FF "\n";
	}
    }    
    close FF;
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

sub GetSampleWithoutReplacements{
    my $matrix_size = $_[0];
    my $sample_size = $_[1];
    
    my $sample_h = {};
    my $sample_count = 0;
                
    while ($sample_count <  $sample_size){
	my $rn = floor(rand($matrix_size));
	if (!exists($sample_h->{$rn})){
            $sample_h->{$rn} = 1;
            $sample_count++;	
	}	
    }
    
    return pdl (keys %{$sample_h});
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PDLDM::Common - This provides a few basic functions required for data mining with PDL.

=head1 SYNOPSIS

    use PDL;
    use PDLDM::Common qw(NormalizeData WritePDL2DtoCSV ReadCSVtoPDL GetSampleWithoutReplacements SetValue);
    
    my $test_pdl = pdl ([[1,2,3,3,4,4,4,5,6,6], [1,1,1,2,2,4,4,5,6,6],[5,3,2,4,2,8,1,0,-2,6]]);
    print "Original: $test_pdl \n";
    NormalizeData($test_pdl);
    print "Normalized: $test_pdl \n";
    
    WritePDL2DtoCSV($test_pdl,'WritePDL2DtoCSV_test.csv');
    
    my $read_csv_pdl = ReadCSVtoPDL('WritePDL2DtoCSV_test.csv');    
    print "CSV Read $read_csv_pdl\n";
    
    my $sample = GetSampleWithoutReplacements(100,10);    
    print "10 samples out of 0 to 99: $sample\n";
    
    print "Original: $test_pdl \n";
    SetValue($test_pdl->slice("2:4,(1)"),pdl(9,9,9),0);
    print "Changed: $test_pdl \n";
    SetValue($test_pdl->slice("2:4,(1)"),pdl(1,1,1),1);
    print "Changed: $test_pdl \n";
    SetValue($test_pdl->slice("2:4,(1)"),pdl(2,2,2),2);
    print "Changed: $test_pdl \n";

=head1 DESCRIPTION

NormalizeData

This function in-place min-max nomarlizes a data piddle.
Since this changes the data piddle in the input parameter, there are no output parameters.
Please make sure you have a copy of your original data, if you need them later.

WritePDL2DtoCSV

Write a 2D piddle to a CSV file.

ReadCSVtoPDL

Read a csv file to a 2D piddle.

WritePDL3DtoCSV

Write a 3D piddle to a CSV file.

GetSampleWithoutReplacements

This produces samples without replacements.

SetValue

Sets values in a piddle.
This is required only when a debugger does not support some PDL functions.
For example with ActiveState Komodo IDE you may need this function when debugging.
SetValue accepts three variables.

1) a piddle that needs to be overwritten, lets say A.
2) a piddle that need to replace A, lets say B.
3) 0: replace A with B. i.e. A = B ;
   1: Add B to A. i.e. A = A + B ;   
   2: Substract B from A = A - B.
   
It changes A inplace, there for no output arguments are required.
The defaults is 0.

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
it under the same terms as Perl itself, either Perl version 5.22.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
