package SmotifCS::EnumerateSmotifCombinations;

use 5.10.1;
use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use SmotifCS::GeometricalCalculations;
use SmotifCS::Protein;
use Data::Dumper;
use Carp;
use Storable qw(dclone);
use DBI;
use Cwd;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
    $VERSION = "0.1";

    #$AUTHOR  = "Vilas Menon(vilas\@fiserlab.org )";
    @ISA = qw(Exporter);

    #Name of the functions to export
    @EXPORT = qw(
      enumerate
      prepare_for_enumeration
      pre_gen_list
    );

    #Name of the functions to export on request
    @EXPORT_OK = qw(
      gen_list
      full_enum
    );
}

use constant DEBUG => 0;
our @EXPORT_OK;
use Config::Simple;
my $config_file = $ENV{'SMOTIFCS_CONFIG_FILE'};
croak "Environmental variable SMOTIFCS_CONFIG_FILE should be set"
  unless $config_file;
my $cfg = new Config::Simple($config_file);

my $pdb                    = $cfg->param( -block => 'pdb' );
my $PDB_PATH               = $pdb->{'pdb_path'};
my $USER_SPECIFIC_PDB_PATH = $pdb->{'user_specific_pdb_path'};

=head1 NAME

EnumerateSmotifCombinations

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

	Module for enumerating combinations of Smotifs to generate full protein models
	
    	Usage:

	use EnumerateSmotifCombinations;

    	EnumerateSmotifCombinations($pdbcode,$mot,$havestructure);

=head1 EXPORT

	enumerate
    full_enum
	prepare_for_enumeration
	pre_gen_list
	gen_list

=head2 prepare_for_enumeration
	
This subroutine prepares all the files needed for enumeration

=cut

sub prepare_for_enumeration {
    use File::Spec::Functions qw(catfile);
    my ( $pdb, $smotifs ) = @_;

    croak "4-letter pdbcode is required" unless $pdb;

    # my $bestfile = "$pdb/$pdb\_motifs_best.csv";
    # my $rmsdfile = "$pdb/$pdb\_motifs_rmsd.csv";
    my $bestfile = catfile( $pdb, "$pdb" . "_motifs_best.csv" );
    my $rmsdfile = catfile( $pdb, "$pdb" . "_motifs_rmsd.csv" );

    if ( -e $bestfile ) { unlink $bestfile }
    if ( -e $rmsdfile ) { unlink $rmsdfile }

    # unlink glob "$pdb/_*-all_enum_$pdb.csv";
    my $all_enum_csv = catfile( $pdb, "_*-all_enum_" . "$pdb\.csv" );
    unlink glob "$all_enum_csv";

    my @bestlist;
    my @rmsdlist;

    opendir( DIR, $pdb ) or croak "$pdb directory does not exist";

    while ( my $file = readdir(DIR) ) {
        if ( $file =~ m/$pdb\_[0-9][0-9]_motifs_best.csv/ ) {

            # my $full_file = "$pdb/$file";
            my $full_file = catfile( "$pdb", "$file" );
            push( @bestlist, $full_file );
        }
        if ( $file =~ m/$pdb\_[0-9][0-9]_motifs_rmsd.csv/ ) {

            # my $full_file = "$pdb/$file";
            my $full_file = catfile( "$pdb", "$file" );
            push( @rmsdlist, $full_file );
        }
    }
    closedir(DIR);

    @bestlist = sort @bestlist;
    @rmsdlist = sort @rmsdlist;

    if ( scalar(@bestlist) < $smotifs ) {
        croak
"One or more smotif ranking file(s) missing. Run steps 1-3 before trying enumeration.";
    }

#if (scalar(@rmsdlist) < $smotifs) {
#        croak "One or more smotif rmsd file(s) missing. Run steps 1-3 before trying enumeration.";
#}

    open( OUT1, ">$bestfile" );
    open( OUT2, ">$rmsdfile" );

    foreach my $bfile (@bestlist) {
        open( IN1, "<", $bfile ) or croak "Unable to open $bfile";
        while ( my $line = <IN1> ) {
            chomp $line;
            print OUT1 "$line\n";
        }
        close(IN1);
        unlink $bfile;
    }
    close(OUT1);

    foreach my $rfile (@rmsdlist) {
        open( IN2, "<", $rfile ) or croak "Unable to open $rfile";
        while ( my $line = <IN2> ) {
            chomp $line;
            print OUT2 "$line\n";
        }
        close(IN2);
        unlink $rfile;
    }
    close(OUT2);
}

=head2 pre_gen_list

Subroutine to generate the input list for enumeration

=cut

sub pre_gen_list {
    use File::Spec::Functions qw(catfile);

    my ( $pdb, $smotifs ) = @_;

    my $half = int( $smotifs / 2 ) - 1;

    # my $bestfile = "$pdb/$pdb\_motifs_best.csv";
    my $bestfile = catfile( $pdb, "$pdb" . '_motifs_best.csv' );
    my @motcount;
    my $i = 0;

    open my $infile, '<', $bestfile
      or croak "Unable to open file $bestfile $!";

    while ( my $line = <$infile> ) {
        chomp $line;
        $i++;
        my @lin = split( /\s+/, $line );
        if ( scalar(@lin) < 2 ) {
            croak "$pdb: smotif $i sampling is inadequate";
        }
        push @motcount, scalar(@lin) - 1;
    }
    close $infile;

    my @keeplist = ();
    my $numtasks = 0;
    my $level    = 0;
    my @joblist;
    # my @joblist = gen_list( \@motcount, $level, \@keeplist, $half, \$numtasks );
    gen_list( \@joblist, \@motcount, $level, \@keeplist, $half, \$numtasks );
    return @joblist;
}

=head2 gen_list

Subroutine to generate the input list for enumeration

=cut

sub gen_list {
    # my ( $motcount, $level, $keeplist, $half, $numtasks ) = @_;
    my (  $aref_joblist, $motcount, $level, $keeplist, $half, $numtasks ) = @_;
    # my @joblist;
    if ( $level == $half ) {
        my $start = '';
        if ( scalar(@$keeplist) > 0 ) {
            for ( my $aa = 0 ; $aa < scalar(@$keeplist) ; $aa++ ) {
                $start = $start . '_' . $$keeplist[$aa];
            }
        }
        for ( my $aa = 0 ; $aa < $$motcount[$level] ; $aa++ ) {

            #print OUTFILE "$start\_$aa ";
            # push( @joblist, "$start\_$aa " );
            push( @{$aref_joblist}, "$start\_$aa " );
            $$numtasks++;
        }
    }
    elsif ( $level < $half ) {
        my @templist = @{ dclone( \@$keeplist ) };
        push( @templist, 0 );
        for ( my $aa = 0 ; $aa < $$motcount[$level] ; $aa++ ) {
            $templist[-1] = $aa;
            # gen_list( \@$motcount, $level + 1, \@templist, $half, \$$numtasks );
             gen_list( $aref_joblist, \@$motcount, $level + 1, \@templist, $half, \$$numtasks );
        }
    }
    else { }
    # return @joblist;
}

=head2 enumerate

This subroutine builds a full enumeration of combinations of given smotifs (stored in a file)
and calculates 4 scoring component values: radius of gyration, statistical pairwise contact
potential, implicit solvation potential, and long range H bond potential.

INPUTS
1. pdbcode - the 4-character name of the folder to store input and output data
2. mot1 - an underscore-delimited set of characters outlining which subset of smotifs to enumerate.
    Example: If there are 4 putative smotifs, each with 5 candidates, _0_2_3 will take the first candidate for
    smotif1, the third candidate for smotif2, the fourth candidate for smotif3, and then enumerate through
    all the candidates for smotif4, resulting in 5 structures total. For the same set, _1 will take the second
    candidate for smotif1, and enumerate all combinations for the following three smotifs, resulting in 5x5x5=125
    candidates.
3. havestructure - either 0 or 1 
                    0 indicate there is no solved structure for comparison 
                    1 indicate solved structure exists in the input folder. 
                    If 1, the RMSD of each enumerated structure (as compared to the solved structure) 
                    will be output, as well as GDT_TS scores for thos structures with RMSD < 10A. 
                    If the no structure option is selected (0), the RMSD and GDT_TS columns of the 
                    output will contain zeros.

REQUIRED FILES (all to be found in the "pdbcode" directory)
   "pdbcode".out - file containing a list of start and end points of smotifs in the query protein, 
                   as well as secondary structure and loop lengths. This is one of the standard 
                   output files of the generate_shift_files.pl script.

  "pdbcode"_motifs_best.csv - file containing a list of candidates for each putative smotif. 
                   This is one of the standard output files of the findranks.pl script.

OUTPUT (to screen)
For each enumerated structure without excessive steric clashes (# backbone atoms within 2A < number of smotifs), tab-delimited
information about the constituent smotifs and the overall structure scoring components is printed to the screen.

Sample line for a structure with 4 smotifs
1.437   0.740   1.867   8.377   224162 148918 54194 127698      1.7483  0.9973  0.9616  1.2306  8.8294  58.8240 12 0 0 0        0

Explanation:
1.437   0.740   1.867   8.377  : RMSDs of the 4 smotif components individually
224162  148918  54194   127698  : Nids of the 4 smotif components
1.7483  : Per-residue radius of gyration z-score
0.9973  : Per-residue pairwise contact potential z-score
0.9616  : Per-residue solvation potential z-score
1.2306  : Long-range H-bond potential z-score
8.8294  : Overall structure RMSD (from solved structure)
58.8250 : Overall structure GDT_TS score
12 0 0 0: List of indices of smotifs, as found in the <pdbcode>_motifs_best.csv file
0       : Number of steric clashes

=cut

sub enumerate {
    use File::Spec::Functions qw(catfile);

    my ( $pdbcode, $mot1, $havestructure ) = @_;
    croak "4-letter pdb code is required" unless $pdbcode;
    croak "Subset list of smotifs is required" unless ($mot1);
    $havestructure = 0 unless $havestructure;

    my @candlist = split( '\_', $mot1 );
    shift(@candlist);

    $mot1 =~ s/\s+//g;

    # my $outfile = $pdbcode."/".$mot1."-all_enum_".$pdbcode.".csv";
    # my $outfile = catfile( $pdbcode, $mot1."-all_enum_".$pdbcode.".csv");
    my $outfile =
      catfile( $pdbcode, "$mot1" . '-all_enum_' . "$pdbcode" . '.csv' );
    unlink $outfile if -e $outfile;

    # if (-e $outfile) {unlink $outfile};
    #print "$outfile\n";

    #Parameters and calculated statistical values

    #Mean per-residue values for radius of gyration, statistical potential,
    #solvation potential, and H-bond potential
    my @zavgs = ( 2.99, -0.32, -0.07, -0.26 );

#Standard deviations of per-residue values for radius of gyration, statistical potential,
#solvation potential, and H-bond potential
    my @zsdevs = ( 0.49, 0.23, 0.47, 0.17 );

    my $base = SmotifCS::Protein->new();
    my @data;

    #Check to see relevant files and directories exist

    my $pdbfilename =
      SmotifCS::GeometricalCalculations::get_full_path_name_for_pdb_code($pdbcode);

    # print " pdbfilename = $pdbfilename\n";
    if ( $havestructure == 1 ) {
        unless ( -e $pdbfilename ) {
            croak "No pdb file $pdbfilename for $pdbcode\n";
        }
    }

    #Open the file containing info about the Smotif types, starting points,
    #and secondary structure and loop lengths of Smotifs in the query protein
    my $seq = '';

# open(INFILE,"$pdbcode/$pdbcode".".out") or croak "Unable to open input file $pdbcode/$pdbcode\.out\n";
# my $pdbcode_out = catfile( $pdbcode, "$pdbcode.out");
    my $pdbcode_out = catfile( "$pdbcode", "$pdbcode" . '.out' );
    open( INFILE, "$pdbcode_out" )
      or croak "Unable to open input file $pdbcode_out\n";

    my $line = <INFILE>;    #ignore header line
    my @lin;
    while ( $line = <INFILE> ) {
        @lin = split( /\s+/, $line );
        push(
            @data,
            [
                (
                    $pdbcode, $lin[1], $lin[3], $lin[5],
                    $lin[6],  $lin[4], 0,       $lin[2]
                )
            ]
        );

#each array in data contains: pdbcode, chain ID, start residue, ss1 length, ss2 length, loop length, 0, smotif type
        $seq .= substr( $lin[7], 0, $lin[4] + $lin[5] );
    }
    $seq .= substr( $lin[7], $lin[4] + $lin[5], $lin[6] );
    close(INFILE);

#If the structure exists, generate the backbone for RMSD and GDT_TS calculations
    if ( $havestructure == 1 ) {
        for ( my $aa = 0 ; $aa < scalar(@data) ; $aa++ ) {
            $base->add_motif( @{ $data[$aa] } );
        }
        $base->stat_table();
    }

#Gather the full list of candidates for each putative smotif in the query structure
    my @motlist;

    # my $motif_list_file = "$pdbcode/$pdbcode"."_motifs_best.csv";
    my $motif_list_file = catfile( $pdbcode, "$pdbcode" . '_motifs_best.csv' );
    open( INFILE, $motif_list_file )
      or croak
      "Unable to open motif list file for enumeration $motif_list_file\n";

    my %rmsdlist;
    for ( my $motcount = 0 ; $motcount < scalar(@data) ; $motcount++ ) {
        my $line = <INFILE>;
        chomp($line);
        my @lin = split( /\s+/, $line );
        my @lin2;
        my @seqlist;
        for ( my $aa = 1 ; $aa < scalar(@lin) ; $aa++ ) {
            if ( in_array( $lin[$aa], @lin2 ) == 0 ) {
                push( @lin2, $lin[$aa] );
            }
        }
        foreach (@lin2) { $rmsdlist{$_} = 0 }
        push( @motlist, [@lin2] );

        #Find individual smotif rmsds, if the real structure exists
        if ( $havestructure == 1 ) {
            my $base2 = SmotifCS::Protein->new();
            $base2->add_motif( @{ $data[$motcount] } );
            foreach (@lin2) {
                my $temp = SmotifCS::Protein->new();
                $temp->add_motif($_);
                my @lm = $temp->one_landmark(0);
                if ( $lm[1] < $data[$motcount][3] ) {
                    $temp->elongate( 0, $data[$motcount][3] - $lm[1] );
                }
                if ( $lm[1] > $data[$motcount][3] ) {
                    $temp->shorten( 0, $lm[1] - $data[$motcount][3] );
                }
                if ( $lm[3] - $lm[1] <
                    $data[$motcount][4] + $data[$motcount][5] )
                {
                    $temp->elongate( -1,
                        $data[$motcount][4] +
                          $data[$motcount][5] -
                          $lm[3] +
                          $lm[1] );
                }
                if ( $lm[3] - $lm[1] >
                    $data[$motcount][4] + $data[$motcount][5] )
                {
                    $temp->shorten( -1,
                        $lm[3] -
                          $lm[1] -
                          $data[$motcount][4] -
                          $data[$motcount][5] );
                }
                my $rm = 0;
                $rm = $temp->rmsd($base2);
                $rmsdlist{$_} = $rm;
            }
        }
    }
    close(INFILE);

    #set up variables for full enumeration
    # empty protein structure, to be filled in during enumeration
    my $test = SmotifCS::Protein->new();

    # list of smotifs used to generate an individual enumeration
    my @rem = ();

    # smoitfs that are fixed i.e. not enumerated
    my @startlist;
    foreach (@data) { push( @startlist, 0 ) }
    for ( my $aa = 0 ; $aa < scalar(@candlist) ; $aa++ ) {
        $startlist[$aa] = $candlist[$aa];
        @{ $motlist[$aa] } = ( $motlist[$aa][ $candlist[$aa] ] );
    }
    if ( $havestructure == 1 ) { $seq = $base->{seq}; }
    open( OUT, ">$outfile" );
    for ( my $aa = 1 ; $aa <= scalar(@data) ; $aa++ ) {
        print OUT "motif$aa RMSD\t";
    }
    for ( my $aa = 1 ; $aa <= scalar(@data) ; $aa++ ) {
        print OUT "motif$aa NID\t";
    }
    print OUT
"Radius of gyration\tStatistical potential\tSolvation potential\tH-bond potential\tRMSD\tSmotif indices\tSteric clashes\n";
    close(OUT);
    full_enum(
        \@motlist,  \@data,         $test,   0,
        \%rmsdlist, \@rem,          $base,   \@startlist,
        \$seq,      $havestructure, \@zavgs, \@zsdevs,
        $outfile
    );
}

=head2 full_enum

Subroutine to recursively run full enumeration

=cut

sub full_enum {
    my (
        $motlist, $data,   $test,      $motnum, $rmsdlist,
        $rem,     $base,   $startlist, $seq,    $havestructure,
        $zavgs,   $zsdevs, $outfile
    ) = @_;

    croak "Input argument missing for enumeration: motlist\n" unless $motlist;
    croak "Input argument missing for enumeration: data\n"    unless $data;
    croak "Input argument missing for enumeration: test\n"    unless $test;
    croak "Input argument missing for enumeration: motnum\n"
      unless defined $motnum;
    croak "Input argument missing for enumeration: rmsdlist\n" unless $rmsdlist;
    croak "Input argument missing for enumeration: rem\n"      unless $rem;
    croak "Input argument missing for enumeration: base\n"     unless $base;
    croak "Input argument missing for enumeration: startlist\n"
      unless $startlist;
    croak "Input argument missing for enumeration: seq\n"    unless $seq;
    croak "Input argument missing for enumeration: zavgs\n"  unless $zavgs;
    croak "Input argument missing for enumeration: zsdevs\n" unless $zsdevs;
    croak "Output filename missing for enumeration: outfile" unless $outfile;

    $havestructure = 0 unless $havestructure;

    if ( $motnum == scalar(@$data) )
    {    #end of a single enumeration, so calculate scores
        my @ster = $test->check_ster_viols( 'all', 2 )
          ;  #check to see how many non-sequential backbone atoms are within 2 A
        if ( $ster[-1] < scalar(@$data) + 1 )
        {    #if there are fewer steric clashes than smotifs, go ahead
            my $newrmsd = 0;
            if ( $havestructure == 1 )
            {    #if solved structure exists, calculate RMSD and GDT_TS
                $newrmsd = $test->rmsd($base);
            }
            $test->get_seq( 0, $test->num_res() - 1, $$seq );

            #calculate and normalize radius of gyration
            my $rad = (
                (
                    $test->radius_of_gyration() /
                      ( ( $test->num_res() )**( 1 / 3 ) )
                ) - $$zavgs[0]
              ) /
              $$zsdevs[0];

            #calculate and normalize solvation potential score
            my $laz = ( $test->lazaridis_new() - $$zavgs[2] ) / $$zsdevs[2];

            #calculate and normalize statistical potential score
            $test->stat_table();
            my $statpot = ( $test->statpot() - $$zavgs[1] ) / $$zsdevs[1];

            #calculate and normalize H-bond potential score
            $test->add_amide_hydrogens();
            my $hb =
              ( $test->calc_long_range_h_bonds() - $$zavgs[3] ) / $$zsdevs[3];

            #Print output to outfile
            open( OUT, ">>$outfile" );
            foreach (@$rem) {
                print OUT sprintf( "%.3f\t", $$rmsdlist{$_} );
            } #RMSDs of each smotif individually (all zeros, if no solved structure exists)
            print OUT "@$rem\t";    #Smotif nids
            print OUT sprintf( "%.4f\t%.4f\t%.4f\t%.4f\t%.4f\t",
                $rad, $statpot, $laz, $hb, $newrmsd )
              ; #Radius of gyration, statistical potential, solvation potential, H-bond potential, RMSD, and GDT_TS of overall structure
            print OUT "@$startlist\t$ster[-1]\n"
              ; #list of indices corresponding to smotifs in the motifs_best.csv file, and steric clash count
            close(OUT);
        }
    }
    else {      #intermediate structure, build recursively
        for ( my $aa = 0 ; $aa < scalar( @{ $$motlist[$motnum] } ) ; $aa++ ) {
            if ( scalar( @{ $$motlist[$motnum] } ) > 1 ) {
                $$startlist[$motnum] = $aa;
            }
            ;    #enumeration phase

            my $newtest = SmotifCS::Protein->new();
            $newtest =
              dclone($test);    #deep-copy the structure that exists so far
            $newtest->add_motif( $$motlist[$motnum][$aa] ); #add the next smotif

 #shorten/elongate the secondary structures to match those for the query protein
            my @lm = $newtest->one_landmark($motnum);
            if ( $motnum == 0 )
            { #first smotif, need to elongate/shorten the initial secondary structure
                if ( $lm[1] < $$data[0][3] ) {
                    $newtest->elongate( 0, $$data[0][3] - $lm[1] );
                }
                if ( $lm[1] > $$data[0][3] ) {
                    $newtest->shorten( 0, $lm[1] - $$data[0][3] );
                }
            }
            if ( $lm[3] - $lm[1] < $$data[$motnum][4] + $$data[$motnum][5] ) {
                $newtest->elongate( -1,
                    $$data[$motnum][4] + $$data[$motnum][5] - $lm[3] + $lm[1] );
            }
            if ( $lm[3] - $lm[1] > $$data[$motnum][4] + $$data[$motnum][5] ) {
                $newtest->shorten( -1,
                    $lm[3] - $lm[1] - $$data[$motnum][4] - $$data[$motnum][5] );
            }

            #count steric clashes within 2A for non-sequential backbone atoms
            my @ster = $newtest->check_ster_viols( 'all', 2 );

            if ( $ster[-1] < scalar(@$data) + 1 )
            { #so far, no excessive steric clashes, so continue building protein
                my @temprem = ();
                if ( scalar(@$rem) > 0 ) {
                    for ( my $bb = 0 ; $bb < $motnum ; $bb++ ) {
                        $temprem[$bb] = $$rem[$bb];
                    }
                }
                push( @temprem, $$motlist[$motnum][$aa] )
                  ;    #append the nid of the smotif just added
                @$rem = @temprem;
                my $nexttest = SmotifCS::Protein->new();

                #recursively build the model structure by adding the next smotif
                $nexttest = full_enum(
                    \@$motlist,  \@$data,        $newtest, $motnum + 1,
                    \%$rmsdlist, \@$rem,         $base,    \@$startlist,
                    \$$seq,      $havestructure, $zavgs,   $zsdevs,
                    $outfile
                );
            }
        }
    }
}

=head2 in_array

Subroutine to check if a scalar element is in an array

=cut

sub in_array {
    my ( $item, @list ) = @_;

    #use Data::Dumper;

    # print Dumper($item,);
    # print Dumper(\@list);
    croak "Item is required\n" unless $item;

    # croak "Array is required\n" unless @list;

    foreach (@list) {
        if ( $item eq $_ ) { return 1 }
    }
    return 0;
}

=head1 AUTHOR

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc EnumerateSmotifCombinations


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


=head1 LICENSE AND COPYRIGHT

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

1;    # End of EnumerateSmotifCombinations
