package SmotifCS::GenerateShiftFiles;

use 5.10.1 ;
use strict;
use warnings;

use SmotifCS::GeometricalCalculations;
use SmotifCS::Protein;
use SmotifCS::MYSQLSmotifs;
use Data::Dumper;
use Carp;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = "0.1";
	
    # $AUTHOR  = "Vilas Menon(vilas\@fiserlab.org )";
    @ISA = qw(Exporter);

    # Name of the functions to export
    @EXPORT = qw(
        run_and_analyze_talos
	count_pdb_smotifs
	count_smotifs
    );

    @EXPORT_OK = qw(
	split_ss_string
	translate
      );    # symbols to export on request
}
use constant DEBUG => 0;

our @EXPORT_OK;

use Config::Simple;
my $config_file = $ENV{'SMOTIFCS_CONFIG_FILE'};
croak "Environmental variable SMOTIFCS_CONFIG_FILE should be set" unless $config_file;

my $cfg    = new Config::Simple($config_file );

my $talos  = $cfg->param(-block=>'talos');
my $TALOS_PATH = $talos->{'path'};
my $TALOS_EXEC = $talos->{'exec'};
my $TALOS_BASEDIR = $talos->{'basedir'};

my $bmrb2talos = $cfg->param(-block=>'bmrb2talos');
my $BMRB2TALOS_EXEC = $bmrb2talos->{'exec'};
my $BMRB2TALOS_PATH = $bmrb2talos->{'path'};

=head1 NAME

GenerateShiftFiles

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This script runs TALOS+ on the chemical shift input file in order to determine 
the secondary structure elements of the unknown protein

INPUT ARGUMENTS:
1) $pdb   :   pdb code (the chemical shift file should be in the subdirectory identified by the pdb code e.g. 1ptf/pdb1ptfshifts.dat)
2) $chain : chain ID (default = A)

INPUT FILES:
In the <pdbcode> folder:
1) pdb<pdbcode>shifts.dat : BMRB-format file with chemical shift data

OUTPUT FILES:
In the <pdbcode> folder:
1) pred<pdbcode>.tab : File with Residue number, name, and estimates for phi and psi angles
2) <pdbcode>.out :File with smotif information: Protein code, Chain, Smotif type, Smotif start residue, Loop length, Length of first
secondary structure, Length of second secondary structure, Sequence
3) pdb<pdbcode>_shiftsXXX.dat : Set of files containing chemical shift data for residues in each smotif

    Usage: 

    use GenerateShiftFiles;

    GenerateShiftFiles($pdb,$chain);

=head1 SUBROUTINES

	run_and_analyze_talos
	count_smotifs
	split_ss_string
	translate

=head2 run_and_analyze_talos

	SUBROUTINE to identify smotifs from TALOS+ determination of secondary structures using chemical shift data

	

=cut

sub run_and_analyze_talos {

        use File::Spec::Functions qw(catfile);
	use File::Copy;
	use Cwd;

    	my ($pdb,$chain) = @_;
	croak "4-letter pdb code is required" unless $pdb;
	croak "Chain id is required"          unless $chain;

	my $dir = getcwd;

	#Preprocess shifts file - make sure the lines under _mol_residue_sequence have only 20 characters each

       	# my $filename = "$pdb/pdb$pdb"."shifts.dat";
       	#my $filename =  catfile($pdb, "pdb$pdb", "shifts.dat");
	my $filename =  catfile($pdb, "pdb$pdb"."shifts.dat");

	croak "Chemical shifts input file $filename is required" unless (-e $filename);
	
     	# my $cmd = "$BMRB2TALOS_PATH/$BMRB2TALOS_EXEC $filename > temp.tab";    #prep file for TALOS+
     	my $talos = catfile($BMRB2TALOS_PATH, $BMRB2TALOS_EXEC); 
     	my $cmd   = "$talos $filename > temp.tab";   #prep file for TALOS+

        system $cmd;
      	croak "$BMRB2TALOS_EXEC failed" unless -e 'temp.tab'; 	

	copy("temp.tab","$TALOS_BASEDIR") or croak "Copy failed: temp.tab to $TALOS_BASEDIR $!";

	chdir($TALOS_BASEDIR);     #cd to TALOS directory
	if (-e "predSS.tab") {unlink "predSS.tab"};
	if (-e "pred.tab")   {unlink "pred.tab"};

      	# $cmd = "$TALOS_PATH/$TALOS_EXEC -in temp.tab";    #run TALOS+
      	my $talos_path = catfile($TALOS_PATH, $TALOS_EXEC); 
        $cmd = "$talos_path -in temp.tab";    #run TALOS+
        system $cmd;

        my $predSS_tab = catfile($TALOS_BASEDIR, "predSS.tab");
      	croak "$TALOS_EXEC failed" unless -e $predSS_tab;

        my $pred_tab = catfile($TALOS_BASEDIR, "pred.tab");
	croak "$TALOS_EXEC failed" unless -e $pred_tab; 

	copy($predSS_tab,"$dir") or croak "Copy failed: predSS.tab to $dir $!";
	copy($pred_tab, "$dir")  or croak "Copy failed: pred.tab to $dir $!";

	if (-e "temp.tab")      {unlink "temp.tab"};
	if (-e "pred.tab")      {unlink "pred.tab"};
	if (-e "predSS.tab")    {unlink "predSS.tab"};
	if (-e "predS2.tab")    {unlink "predS2.tab"};
	if (-e "predAll.tab")   {unlink "predAll.tab"};
	if (-e "predABP.tab")   {unlink "predABP.tab"};
	if (-e "predAdjCS.tab") {unlink "predAdjCS.tab"};

	chdir($dir);	#cd back to original directory

	#Identify the start and end points of the secondary structures based on the TALOS+ output
        open( INFILE1, "predSS.tab" ) or croak "No secondary structure file predSS.tab\n";
        my $sslist;
        my $seq;
        while ( my $line = <INFILE1> ) {
            if ( $line =~ /^DATA PREDICTED_SS/ )
            {      #Get dominant secondary structure type for each position
                chomp($line);
                my @lin = split( '\s+', $line );
                for ( my $aa = 2 ; $aa < scalar(@lin) ; $aa++ ) {
                    $sslist = $sslist . $lin[$aa];
                }
            }
            if ( $line =~ /^DATA SEQUENCE/ )
            {      #Get residue type for each position
                chomp($line);
                my @lin = split( '\s+', $line );
                for ( my $aa = 2 ; $aa < scalar(@lin) ; $aa++ ) {
                    $seq = $seq . $lin[$aa];
                }
            }
        }
        close(INFILE1);
        print "TALOS+ assignment of secondary structures completed\n";

        #find start residue, if it isn't 0
        my $shiftindex = 0;
        my $fileindex  = 0;
        open (INFILE, $filename) or croak "Unable to open chemical shifts file $filename\n";
      	LOOP: while ( my $line = <INFILE> ) {
            if ( $line =~ /\s+\d+\s+(\d+)\s+(\d+)\s+\w\w\w\s+\w+\s+\w+\s+/ ) {
                $shiftindex = $1;
                $fileindex  = $2;
                last LOOP;
            }
            if ( $line =~ /^\d+\s+(\d+)\s+\w\w\w\s+\w+\s+\w+\s+/ ) {
                $shiftindex = $1;
                $fileindex  = $1;
                last LOOP;
            }
            if ( $line =~ /\s+\d+\s+\.\s+(\d+)\s+\w\w\w\s+\w+\s+\w+\s+/ ) {
                $shiftindex = $1;
                $fileindex  = $1;
                last LOOP;
            }
            if ( $line =~ /\s+\d+\s+(\d+)\s+\w\w\w\s+\w+\s+\w+\s+\d+/ ) {
                $shiftindex = $1;
                $fileindex  = $1;
                last LOOP;
            }
        }
        close(INFILE);
        $sslist = substr( $sslist, $fileindex - 1, length($sslist) - $fileindex + 1 );
        $seq = substr( $seq, $fileindex - 1, length($seq) - $fileindex + 1 );
        #print $shiftindex, "\t", $fileindex, "\n";

        #print out torsion angles for each smotif
        my $pred_pdb_tab = catfile("$pdb", "pred$pdb.tab");
        
        open( INFILE,  "pred.tab")        or croak "Unable to open talos output file pred.tab";
        open( OUTFILE, ">$pred_pdb_tab" ) or croak "Unable to open output file $pred_pdb_tab";
        # open( OUTFILE, ">$pdb/pred$pdb\.tab" ) or croak "Unable to open output file $pdb/pred$pdb\.tab\n";
        print OUTFILE "Residue#\tAA\tPhi angle\tPsi angle\n";
      LOOP: while ( my $line = <INFILE> ) {
            if ( $line =~ /\s+(\d+)\s+\w/ ) {
                my $ind = $1;
                if ( $ind >= $fileindex ) {
                    $line =~ s/^\s+//g;
                    my @lin = split( '\s+', $line );
                    print OUTFILE $lin[0] + $shiftindex - $fileindex,
                      "\t$lin[1]\t$lin[2]\t$lin[3]\n";
                }
            }
        }
        close(OUTFILE);

	#Convert series of secondary structure types into start and end positions of smotifs
        my $start = 0;
	my @ss = split_ss_string( $sslist, \$start );
	#Print smotif information to pdbcode.out file
	
	my $pdb_pdb_out = catfile($pdb, "$pdb.out");
        open (OUTFILE, ">$pdb_pdb_out") or croak "No output file $pdb_pdb_out\n";
        print OUTFILE "Name\tChain\tType\tStart\tLooplength\tSS1length\tSS2length\tSequence\n";
        for (my $aa=0; $aa<(scalar(@ss)-1) / 2; $aa++) {
            print OUTFILE "$pdb";
            print OUTFILE ".pdb\t$chain\t";
            print OUTFILE $ss[ $aa * 2 ][0];
            print OUTFILE $ss[ $aa * 2 + 2 ][0];
            print OUTFILE "\t", $start + $shiftindex, "\t";
            print OUTFILE scalar( @{ $ss[ $aa * 2 + 1 ] } ), "\t";
            print OUTFILE scalar( @{ $ss[ $aa * 2 ] } ), "\t";
            print OUTFILE scalar( @{ $ss[ $aa * 2 + 2 ] } ), "\t";
            my $len =
              scalar( @{ $ss[ $aa * 2 ] } ) +
              scalar( @{ $ss[ $aa * 2 + 1 ] } ) +
              scalar( @{ $ss[ $aa * 2 + 2 ] } );
            print OUTFILE substr( $seq, $start, $len ), "\n";
            $start +=
              scalar( @{ $ss[ $aa * 2 ] } ) + scalar( @{ $ss[ $aa * 2 + 1 ] } );
        }
        close(OUTFILE);

    #generate chem shift file for each smotif
    open( INFILE, "$pdb_pdb_out" ) or croak "No output file $pdb_pdb_out\n";
    my $line = <INFILE>;    #ignore header line
    my @motlist;
    my $count = 1;
    while ( my $line = <INFILE> )
    {    #for each smotif, extract and print out all the chemical shifts
        chomp($line);
        #print "$line\n";
        my @lin   = split( '\s+', $line );
        my $start = $lin[3];
        my $end   = $lin[3] + $lin[5] + $lin[4] + $lin[6] - 1;
	
        # my $filename2="$pdb/pdb"."$pdb"."_shifts"."$count".".dat";
	my $filename2 = catfile ($pdb, "pdb$pdb\_shifts$count.dat");
        open(OUTFILE,">$filename2") or croak "Unable to open output file $filename2";
        open(INFILE2, $filename)    or croak "Unable to open chemical shifts file $filename";

        while ( my $line2 = <INFILE2> ) {
            if ( $line2 =~
/^\s*(\d+)\s+(\d+).+(\w\w\w)\s+(\w+)\s+\w\s+(\d+\.?\d*)\s+(\d*\.\d*)\s+/
              )
            {
                if (   ( $4 eq 'H' )
                    or ( $4 eq 'CA' )
                    or ( $4 eq 'C' )
                    or ( $4 eq 'CB' )
                    or ( $4 eq 'HA' )
                    or ( $4 eq 'N' ) )
                {
                    if ( ( $2 <= $end ) and ( $2 >= $start ) ) {
                        my $res = translate($3);
                        my $sd  = $6;
                        if ( $sd eq '.' ) { $sd = 0.0 }
                        print OUTFILE "$2\t$res\t$4\t$5\t$6\n";
                    }
                }
            }
            if ( $line2 =~
/^\s*(\d+)\s+\.\s+(\d+).+(\w\w\w)\s+(\w+)\s+\w\s+(\d+\.?\d*)\s+(\d*\.\d*)\s+/
              )
            {
                if (   ( $4 eq 'H' )
                    or ( $4 eq 'CA' )
                    or ( $4 eq 'C' )
                    or ( $4 eq 'CB' )
                    or ( $4 eq 'HA' )
                    or ( $4 eq 'N' ) )
                {
                    if ( ( $2 <= $end ) and ( $2 >= $start ) ) {
                        my $res = translate($3);
                        my $sd  = $6;
                        if ( $sd eq '.' ) { $sd = 0.0 }
                        print OUTFILE "$2\t$res\t$4\t$5\t$6\n";
                    }
                }
            }
        }
        close(INFILE2);
        close(OUTFILE);
        $count++;
    }
    close(INFILE);

    if ( $count == 2 ) { warn "$pdb$chain contains only 1 S-motif\n"; }
    if ( $count > 8 ) {
        my $count1 = $count - 1;
        warn "$pdb$chain contains $count1 S-motifs. The following steps in the prediction algorithm may be slower than expected.\n";
    }

    if (-e "temp.tab")      {unlink "temp.tab"};
    if (-e "pred.tab")      {unlink "pred.tab"};
    if (-e "predSS.tab")    {unlink "predSS.tab"};
}

=head2 split_ss_string

	SUBROUTINE to convert a series of secondary structure types to a list of 
    start and end points for smotifs

    Input 1: $ss - a string of secondary structure types, 
             where H=alpha helix and E=strand e.g. (HHHHLLLLEEEE)
	
    Input 2: $startpos - residue at which first smotif begins
	
    Output  : Array containing Smotif definitions

=cut

sub split_ss_string {

    my ( $ss, $startpos ) = @_;
    croak "Secondary structure string input is required" unless $ss;
    croak "Starting position of the first secondary structure is required" unless $startpos;

    my @ss = split( '', $ss );

    #Convert all non-helical and non-strand amino acids to loop "L"
    foreach (@ss) {
        if ( ( ($_) ne 'H' ) and ( ($_) ne 'E' ) ) { $_ = 'L' }
    }
    #Convert all strand with length < 2 to loop "L"
    my $sslength = 1;
    my $prev     = $ss[0];
    for ( my $count = 1 ; $count < scalar(@ss) ; $count++ ) {
        if ( $ss[$count] eq $prev ) {
            $sslength++;
        }
        else {
            if (   ( ( $sslength < 2 ) and ( $prev ne 'L' ) )
                or ( ( $sslength < 4 ) and ( $prev eq 'H' ) ) )
            {
                for ( my $aa = $count - $sslength ; $aa < $count ; $aa++ ) {
                    $ss[$aa] = 'L';
                }
            }
            $prev     = $ss[$count];
            $sslength = 1;
        }
    }
    my @out;
    my $start = 0;
    for ( my $aa = 0 ; $aa < scalar(@ss) - 1 ; $aa++ ) {
        if ( $ss[$aa] ne $ss[ $aa + 1 ] )
        {    #switch in secondary structure type implies a landmark
            push( @out, [ @ss[ $start .. $aa ] ] );
            if ( ( $ss[$aa] ne 'L' ) and ( $ss[ $aa + 1 ] ne 'L' ) ) {
                $ss[ $aa + 1 ] = 'L';
            }
            $start = $aa + 1;
        }
    }
    if ( $out[0][0] eq 'L' ) {
        $$startpos = scalar( @{ $out[0] } );
        shift(@out);
    }
    if ( $out[-1][0] eq 'L' ) { pop(@out) }
    return @out;
}

=head2
	Subroutine to count the number of Smotifs in a given Smotif definition file (typically $pdb/$pdb.out). 
	Input : Filename with Smotif definition
	Output: Returns the number of Smotifs in the given file
=cut

sub count_smotifs {

	my ($filename) = @_;

	open(INFILE, $filename) or croak "Unable to open Smotif definition file $filename\n";
	my $smotifs = 0;
	my $line = <INFILE>;      #skip header line
	while (my $line = <INFILE>) {
		chomp $line;
		my @lin = split ('\s+',$line);
		if (scalar(@lin) == 8) {
        		$smotifs++;
		} else {
			croak "Unrecognized file format in $filename\n";
			return;
		}
	}
	close (INFILE);	
	return $smotifs;
}

=head2
	Subroutine to count the number of Smotifs in a given Smotif definition file (typically $pdb/$pdb.out). 
	Input : Filename with Smotif definition
	Output: Returns the number of Smotifs in the given file
=cut

sub count_pdb_smotifs {
        my ( $pdb ) = @_;
        use File::Spec::Functions qw(catfile);

        croak "4-letter pdb code is required" unless $pdb;

	# my $filename = "$pdb\/$pdb" . ".out";
	my $filename = catfile( $pdb, "$pdb.out" );
        
        croak "$filename does not exists. First run 'run_and_analyze_talos' step 1." 
	    unless ( -e $filename );
        
        my $smotifs = count_smotifs( $filename );
        return $smotifs;
}

=head2
	SUBROUTINE to convert 3-letter amino acids into single-letter codes	
	Input: 3-letter amino acid code
	Output: Corresponding 1-letter amino acid code
=cut

sub translate {
    my ($inp) = @_;

    croak "3-letter amino acid input is required" unless $inp;

    my $out;

    if    ( $inp eq 'ALA' ) { $out = 'A' }
    elsif ( $inp eq 'CYS' ) { $out = 'C' }
    elsif ( $inp eq 'ASP' ) { $out = 'D' }
    elsif ( $inp eq 'GLU' ) { $out = 'E' }
    elsif ( $inp eq 'PHE' ) { $out = 'F' }
    elsif ( $inp eq 'GLY' ) { $out = 'G' }
    elsif ( $inp eq 'HIS' ) { $out = 'H' }
    elsif ( $inp eq 'ILE' ) { $out = 'I' }
    elsif ( $inp eq 'LYS' ) { $out = 'K' }
    elsif ( $inp eq 'LEU' ) { $out = 'L' }
    elsif ( $inp eq 'MET' ) { $out = 'M' }
    elsif ( $inp eq 'ASN' ) { $out = 'N' }
    elsif ( $inp eq 'PRO' ) { $out = 'P' }
    elsif ( $inp eq 'GLN' ) { $out = 'Q' }
    elsif ( $inp eq 'ARG' ) { $out = 'R' }
    elsif ( $inp eq 'SER' ) { $out = 'S' }
    elsif ( $inp eq 'THR' ) { $out = 'T' }
    elsif ( $inp eq 'VAL' ) { $out = 'V' }
    elsif ( $inp eq 'TRP' ) { $out = 'W' }
    elsif ( $inp eq 'TYR' ) { $out = 'Y' }
    else  { croak "Unknown amino acid type $inp\n" };
    return $out;
}

=head1 AUTHOR

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc GenerateShiftFiles


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=.>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/.>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/.>

=item * Search CPAN

L<http://search.cpan.org/dist/./>

=back


=head1 ACKNOWLEDGEMENTS



Copyright 2015 Fiserlab Members .

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of GenerateShiftFiles
