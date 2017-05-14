package SmotifTF::RankSmotifs;

use 5.8.8 ;
use strict;
use warnings;
use SmotifTF::GeometricalCalculations;
use SmotifTF::Protein;
use SmotifTF::Psipred;
use Data::Dumper;
use Carp;
use File::Spec::Functions qw(catfile);
use Storable qw(dclone);
use Cwd;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = "0.01";

    @ISA = qw(Exporter);

    # name of the functions to export
    @EXPORT = qw(
    rank_all_smotifs
    );

    @EXPORT_OK = qw(
    find_ranks_by_evalue
      );    # symbols to export on request
}
use constant DEBUG => 0;

our @EXPORT_OK;

=head1 NAME

RankSmotifs

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    Subroutines to rank smotifs based on e-values obtained from HMM comparisons. 

    use RankSmotifs;

    rank_all_smotifs($pdbcode);
    

=head1 EXPORT

    rank_all_smotifs
    find_ranks_by_evalue

=head1 SUBROUTINES

    rank_all_smotifs
    find_ranks_by_evalue


=head2 rank_all_smotifs

Script to rank smotifs in the database by their e-values

INPUT ARGUMENTS
1) $pdbcode : 4-letter pdbcode

INPUT FILES
In the <pdbcode> folder:
1) dd_shiftcands<pdbcode><motnum>_<looplength><smotif type>.csv : Files containing results of 
comparing the query smotifs against the database. 

OUTPUT FILES
In the <pdbcode> folder:
1) <pdbcode>_motifs_best.csv : File containing a list of smotif candidates for each query smotif in the unknown protein
2) <pdbcode>_motifs_rmsd.csv : File containing rmsds of smotif candidates for each query smotif in the unknown protein.

=cut

sub rank_all_smotifs {

    my ($pdbcode)=@_;
    croak "4-letter pdb code is required" unless $pdbcode;

        my $tmpfile = "list.dat";
        #print "$tmpfile\n";

        #Get the list of all smotif comparison files in the directory
        my $cmd = "ls $pdbcode/dd_shiftcands$pdbcode* > $tmpfile";
        system $cmd;
        #`ls $pdbcode/dd_shiftcands$pdbcode* > $tmpfile`;

=for    
    # Added by CMA to replace my `ls $pdbcode/dd_shiftcands$pdbcode* > $tmpfile`;
    # for something more portable 
    my $look_for= catfile( $pdbcode, "dd_shiftcands$pdbcode*");
    # print "look_for= $look_for\n";
    my @found   = glob $look_for;
    
    die "rank_smotifs: no file like dd_shiftcands$pdbcode* was found in $pdbcode"
        unless @found;
    # Let's assume that just ONE file like $pdbcode/$nam*csv was found.
    # $nam2  = 1aab/shiftcands1aab_01_8HH.csv
    my $nam2 = $found[0];
=cut

        #Find the number of compare smotif files
        my $num_f=0;
        open(INFILE, "<$tmpfile") or croak "Unable to open $tmpfile";
        while (my $line=<INFILE>) {
                if ($line=~/$pdbcode\/dd_shiftcands/) {
                    $num_f++;
                }
        }
        close(INFILE);

        #Find the number of smotifs
        my $smot_file = catfile ($pdbcode, "$pdbcode.out");
        croak ("$smot_file does not exist") unless -e $smot_file;
        my $num_mots = SmotifTF::Psipred::count_smotifs ($smot_file);

        unless ($num_f == $num_mots) {croak "Missing compare smotif files. Rerun compare smotifs step."};

    #Set the number of candidates for each smotif. For smaller proteins, raise the number of smotifs
    my $num_candidates; #number of candidates for each smotif, to be used for full enumeration
    if ($num_mots>14) {
        croak "Number of Smotifs in the query is greater than the current limit of 14";
    } elsif ($num_mots>11) {
        $num_candidates = 3;
    } elsif ($num_mots>9) {
        $num_candidates = 4;
    } elsif ($num_mots==9) {
        $num_candidates = 5;
    } elsif ($num_mots==8) {
        $num_candidates = 6;
    } elsif ($num_mots==7) {
        $num_candidates = 8;
    } elsif ($num_mots==6) {
        $num_candidates = 11;
    } elsif ($num_mots==5) {
        $num_candidates = 16;
    } elsif ($num_mots<5) {
        $num_candidates = 24;
    } elsif ($num_mots<2) {
        croak "Number of Smotifs in the query is smaller than the current limit of 2";
    }

    #Clean older files

    my $rmsdfile = catfile ($pdbcode, "$pdbcode\_motifs_rmsd.csv");
    my $bestfile = catfile ($pdbcode, "$pdbcode\_motifs_best.csv");

    if (-e $rmsdfile) { unlink $rmsdfile };
    if (-e $bestfile) { unlink $bestfile };

    #For each smotif comparison file, rank the smotifs
        open(INFILE2, "<$tmpfile") or croak "Unable to open $tmpfile";
        while (my $line=<INFILE2>) {
                chomp($line);
                #Get information about query smotif from the filename
                if ($line=~/$pdbcode\/dd_shiftcands(\w+)\.csv/) {
                        my $filename=$1;
                        my $count=0;
                        my $looplen;
                        #Get loop length from filename
                        if ($filename=~/\w+\_(\d+)\_(\d+)../) {
                                $count=$1-1;
                                $looplen=$2;
                        }
                        #Get the query sequence
                        find_ranks_by_evalue($filename,$num_candidates,$pdbcode);
                }
        }
        close(INFILE2);
        if (-e $tmpfile) {unlink $tmpfile};
}

=head2 find_ranks_by_evalue

Subroutine to rank all the evaluated candidates for a single query smotif

=cut

sub find_ranks_by_evalue {

    my($filename,$num_candidates,$pdbcode)=@_;

    croak "Smotif e-value comparison filename is required"     unless $filename;
    croak "Number of candidates to be shortlisted is required" unless $num_candidates; 
    croak "4-letter pdb code is required" unless $pdbcode;

    my $shiftcandsfilename=catfile ($pdbcode, "dd_shiftcands$filename.csv");
    open(INFILE3,$shiftcandsfilename) or croak "Unable to open $shiftcandsfilename";    #if file does not exist
    my $line=<INFILE3>; #ignore header line
    my $check=0;

    #Read input data from comparison file
    my @fullranks;
    while (my $line=<INFILE3>) {
        chomp($line);
        my @lin=split(/\s+/, $line);
        push(@fullranks,[@lin]);
        $check++;
    }
    close(INFILE3);

    if ($check==0) {
        croak "Error: No Smotifs are found in $shiftcandsfilename. 
               Rerun Blast / Delta-Blast / HHblits with lenient cutoffs.";
    }

    #Rank by evalue

    @fullranks = sort {($a->[2] <=> $b->[2])} @fullranks;

    #find lowest and mean rmsd of the entire filtered set
    my $fullmin=100;
    my $fullmean=0;
    for (my $aa=0;$aa<scalar(@fullranks);$aa++) {
        if (($fullranks[$aa][2]<$fullmin)) {$fullmin=$fullranks[$aa][2]}
        $fullmean += $fullranks[$aa][2];
    }
    $fullmean /= scalar(@fullranks);

    ####Choose ranked Smotifs

        my @motlist;
        my @motrmsds;
        my $ac=0;

        while (($ac<$num_candidates) and ($ac<scalar(@fullranks))) {
                push(@motlist,$fullranks[$ac][5]);
                push(@motrmsds,$fullranks[$ac][3]);
                $ac++;
        }

        #find lowest and mean rmsd of the selected set
        my $bestmin=100;
        my $bestmean=0;
        foreach (@motrmsds) {
                $bestmean += $_/scalar(@motrmsds);;
                if ($_<$bestmin) {$bestmin=$_}
        }
        my $bestmeanprint = sprintf("%.3f",$bestmean);
        my $bestminprint = sprintf("%.3f",$bestmin);
        my $fullminprint = sprintf("%.3f",$fullmin);
        my $fullmeanprint = sprintf("%.3f",$fullmean);

        #Print output files
        my $rmsdfile = catfile ($pdbcode, "$pdbcode\_motifs_rmsd.csv");
        my $bestfile = catfile ($pdbcode, "$pdbcode\_motifs_best.csv");

        open(MOTIFRMSDS,">>$rmsdfile");
        open(MOTLISTOUT,">>$bestfile");
        print MOTLISTOUT "$filename\t";
        for (my $aa=0;$aa<scalar(@motlist);$aa++) {
                        print MOTLISTOUT "$motlist[$aa]\t";
                        print MOTIFRMSDS "$motlist[$aa]\t$motrmsds[$aa]\t$filename\n";
        }
        print MOTLISTOUT "\n";
        print MOTIFRMSDS "\n";
        close(MOTIFRMSDS);
        close(MOTLISTOUT);
}

=head1 AUTHORS

Fiserlab members, C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RankSmotifs

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

Copyright 2015 Brinda Vallat, Vilas Menon .

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

1; # End of RankSmotifs
