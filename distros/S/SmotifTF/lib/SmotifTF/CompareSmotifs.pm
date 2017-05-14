package SmotifTF::CompareSmotifs;

use 5.8.8 ;
use strict;
use warnings;
use SmotifTF::GeometricalCalculations;
use SmotifTF::Protein;
use Data::Dumper;
use Carp;
use File::Spec::Functions qw(catfile);

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = "0.01";

    @ISA = qw(Exporter);

    # name of the functions to export
    @EXPORT = qw(
    test_motif 
    );

    @EXPORT_OK = qw(
    check_pdb 
    get_evalue   
    trim 
    ltrim
    rtrim
    match_in_array 
    get_hhm 
    read_dd_info
      );    # symbols to export on request
}
use constant DEBUG => 0;

our @EXPORT_OK;

=head1 NAME

CompareSmotifs

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Subroutines to compare a given query Smotif to all the Smotifs in the dynamic database,
compute e-values using the HHsuite and provide a list of suitable Smotifs based on
the e-values. 

    use CompareSmotifs;

    test_motif($pdb,$havestructure,$motnum);

=head1 SUBROUTINES

    test_motif
    check_pdb 
    get_evalue   
    trim 
    ltrim
    rtrim
    match_in_array 
    get_hhm 
    read_dd_info

=cut

use Config::Simple;
my $config_file = $ENV{'SMOTIFTF_CONFIG_FILE'};
croak "Environmental variable SMOTIFTF_CONFIG_FILE should be set" unless $config_file;
my $cfg      = new Config::Simple($config_file);
my $hhsuite  = $cfg->param(-block=>'hhsuite');
my $HHSUITE_PATH    = $hhsuite->{'path'};
my $HHBLITS_DB_PATH = $hhsuite->{'db_path'};
my $HHBLITS_DB      = $hhsuite->{'nr_hhm_db'};
my $HHBLITS_EXEC    = $hhsuite->{'hhblits'};
my $HHMAKE_EXEC     = $hhsuite->{'hhmake'};
my $HHALIGN_EXEC    = $hhsuite->{'hhalign'};

=head2 test_motif

Subroutine to compare Smotifs from a query protein against a dynamic database of Smotifs using hidden
markov model profiles. 

INPUT ARGUMENTS
1) $pdb : 4-letter pdb code (with a directory in the current folder with the same name).
2) $havestructure : 0=no solved structure for RMSD comparison, 1=solved structure exists for RMSD comparison
3) $motnum : which smotif of the protein to compare (0=1st smotif, 1=2nd smotif, and so on)

INPUT FILES
In the <pdbcode> folder:
1) <pdbcode>.out : Standard file with information about each Smotif - Smotif definitions
2)dd_info_evalue.out : File with information about all Smotifs in the dynamic database. 

OUTPUT FILES
In the <pdbcode> folder:
1) dd_shiftcands<pdbcode><motnum>_<looplength><smotif type>.csv : File containing results of comparing the 
query smotif against the database. Includes the number of residues compared, the e-values from HMM-HMM comparisons, 
the RMSD (if structure is included), the loop length, the smotif NID, the secondary structure RMSD, 
secondary structure lengths, and loop structural signatures for the query and database motif and their overlap.

=cut

sub test_motif {
    my ($pdb,$havestructure,$motnum)=@_;

    croak "4-letter pdb code is required" unless $pdb;
    croak "Motif number is required"      unless $motnum;
    $havestructure = 0 unless $havestructure;

    my $num_hits = 0;
    my $pdbname = $pdb;
    my $line;

    #Get information about the putative smotif
    
    my $pdb_pdb_out = catfile($pdb, "$pdb.out");
    #print "$pdb_pdb_out\n";
    open(INFILE3,"$pdb_pdb_out") or croak "no file $pdb_pdb_out to compare shifts";
    $line = <INFILE3>;    #skip header line
    for (my $cc = 0; $cc < $motnum; $cc++) {
        $line=<INFILE3>;
        chomp($line);
        #print "$cc\t$line\n";
    }
    close(INFILE3);
    #chomp($line);
    my @lin=split(/\s+/, $line);
    my $expseq=$lin[7];

    # Leeway for Loop Length
    my $lenlimit=5;     #Leeway for loop length
    if (($lin[5]<11) or ($lin[6]<11)) {$lenlimit=4};
    if (($lin[5]<9) or ($lin[6]<9)) {$lenlimit=3};
    if (($lin[5]<7) or ($lin[6]<7)) {$lenlimit=2};
        if (($lin[5]<5) or ($lin[6]<5)) {$lenlimit=1};
    if (($lin[5]<3) or ($lin[6]<3)) {$lenlimit=0};

    # E-value cutoff for benchmarking only
    my $ecut = 0.000001;

    if ($havestructure==1) {
        my $error = check_pdb($pdbname,$lin[1],$lin[2],$lin[3],$lin[4],$lin[5],$lin[6]);
            if ($error==1) {
            $havestructure=0;
            #print "PDB ERROR\n";
        }
    }

    #get backbone coordinates, if structure exists
        my $base=SmotifTF::Protein->new();
        if ($havestructure==1) {
                $base->add_motif($pdbname,$lin[1],$lin[3],$lin[5],$lin[6],$lin[4],0,$lin[2]);
        }

    ###Get information about the dynamic database entries

    my $dd_file = catfile($pdb,"dd_info_evalue.out");
    my @ddlist = read_dd_info($dd_file);

    ###Output file
    my $shiftnumber = $motnum;
    my $name=sprintf("%02d",$shiftnumber);
    
    my $outfile = catfile($pdb, "dd_shiftcands$pdb"."_".$name."_"."$lin[4]$lin[2]".".csv");
    open(OUTFILE,">$outfile") or croak "Unable to open $outfile";
    print OUTFILE "No.\tProt Evalue\tSmot E Value\tRMSD\tLoop length\tNID\tSequence\tRMSD_SS\tSS1 length\tSS2 length\n";

    #Compare relevant smotifs

    FLOOP:for (my $dd=0; $dd<scalar(@ddlist); $dd++) {

        my @list=split ('\s+', $ddlist[$dd]);

        if (($list[3] eq 'AR') or ($list[3] eq 'JA')) {$list[3]='EE'};
        if ($list[3] ne $lin[2]) {next FLOOP}    #Not same smotif type
                if (($list[5]<$lin[4]-$lenlimit) or ($list[5]>$lin[4]+$lenlimit)) {next FLOOP} #Not similar loop length
        #if ($list[11] < $ecut) {next FLOOP}    #E-value cutoff  for benchmarking only

        # Check for insertions and missing residues

        print "$list[1]\n";
        my $pdb_error = check_pdb($list[1],$list[2],$list[3],$list[4],$list[5],$list[6],$list[7]);
        if ($pdb_error==1) {next FLOOP};

        my $libseq=$list[8];
        if ($libseq =~ /B|J|O|U|X|Z/) {next FLOOP}; #non-standard amino acid

        #calculate rmsd between experimental smotif and library smotif, if structure exists
        my $rmsd=0;
        my $rmsdss=0;
        my $check;
        if ($havestructure==1) {
            print "$pdb\t$list[0]\t$list[1]\t$list[2]\n";
            my $test=SmotifTF::Protein->new();
            $check=$test->add_motif($list[1],$list[2],$list[4],$list[6],$list[7],$list[5],0,$list[3]);
            #if ($check==0) {next FLOOP}
            if ($list[6]<$lin[5]) {$test->elongate(0,$lin[5]-$list[6])}
            if ($list[6]>$lin[5]) {$test->shorten(0,$list[6]-$lin[5])}
            if ($list[5]+$list[7]<$lin[4]+$lin[6]) {$test->elongate(-1,$lin[4]+$lin[6]-$list[5]-$list[7])}
            if ($list[5]+$list[7]>$lin[4]+$lin[6]) {$test->shorten(-1,$list[5]+$list[7]-$lin[4]-$lin[6])}
            $rmsd=$test->rmsd($base);
            $rmsdss=$test->rmsd_ss($base);
        }

        #Get evalue between smotifs

        my $eval=get_evalue($expseq,$libseq,$pdb,$shiftnumber);
        my $prot_eval=$list[-1];

        #Print to output file
        my $nn = $num_hits+1;
        print OUTFILE "$nn\t$prot_eval\t$eval\t$rmsd\t$list[5]\t";
        print OUTFILE "$list[0]\t$libseq\t$rmsdss\t$list[6]\t$list[7]\n";
        $num_hits++;
    }
    close(OUTFILE);
    close(INFILE3);
    if ($num_hits < 20) {
        print "Warning:\t$pdb\t$shiftnumber\tMake Blast more lenient\n";
    }
}

=head2 check_pdb

Subroutine to check pdb file for missing residues and insertions. 

=cut

sub check_pdb {

my ($pdb,$chain,$type,$start,$length,$ss1length,$ss2length) = @_;

    croak "4-letter pdb code is required" unless $pdb;
    croak "Chain ID is required"          unless $chain; 
    croak "Smotif type is required"       unless $type;
    croak "Smotif start is required"      unless $start;
    croak "Loop length is required"       unless $length;
    croak "SS1 length is required"        unless $ss1length;
    croak "SS2 length is required"        unless $ss2length;

    my $end=$start+$ss1length+$length+$ss2length-1;
    my @list;
    my $pdb_error=0;
    my $filename = SmotifTF::GeometricalCalculations::get_full_path_name_for_pdb_code($pdb,$chain);

    #print "Checking errors on $filename\n";

    my $fh;
        if ($filename =~ /\.gz$/) {
                open $fh, '-|', 'gzip', '-dc', $filename or croak "No file exists $filename\n";
        } else {
                open $fh, $filename or croak "No file exists $filename\n";
        }

        my @pdb_lines = <$fh>;
        chomp @pdb_lines;
        close $fh;

        WLOOP: foreach my $line (@pdb_lines) {
                if (($line=~/^ENDMDL/)) {
                    last WLOOP;
                } elsif (($line=~/^ATOM/) or (($line=~/^HETATM/) and (substr($line,17,3) eq 'MSE'))) {
                    if (substr($line,21,1) eq $chain) {
                        my $ll = substr($line,22,4);
                        my $lin = ltrim($ll);
                        push(@list,$lin);
                        if (($lin>=$start) and ($lin<=$end)) {
                            if ($lin =~ /[A-Z]/) {
                                print "Error:\t$lin\n";
                                $pdb_error=1;
                                next WLOOP;
                            }
                            if (scalar(@list)>1) {
                                if (($lin-$list[-2]) > 1) {
                                    print "ERROR:\t$pdb\t$chain\t$start\t$end\t$lin\t$list[-2]\t$list[-1]\n";
                                    $pdb_error=1;
                                    next WLOOP;
                                }
                            }
                        }
                    }
                }
       }
            FLOOP: for (my $aa=$start;$aa<=$end;$aa++) {
                if (match_in_array($aa,@list)) {
                    next FLOOP;
                } else {
                    $pdb_error=1;
                }
            }

    return $pdb_error;
}

=head2 get_evalue

Subroutine to get evalue given two sequences 

=cut

sub get_evalue {
    my($seq1,$seq2,$pdb,$num)=@_;

    croak "Sequence 1 is required" unless $seq1;
    croak "Sequence 2 is required" unless $seq2;
    croak "4-letter pdb code is required" unless $pdb;
    croak "Pair number is required" unless $num;

    my $name1 = "test".$num;
    my $name2 = "temp".$num;

    get_hhm($pdb,$name1,$seq1);
    get_hhm($pdb,$name2,$seq2);

    my $hhalign  = catfile ($HHSUITE_PATH, $HHALIGN_EXEC);
    my $hhmfile1 = catfile ($pdb, "$name1.hhm");
    my $hhmfile2 = catfile ($pdb, "$name2.hhm");
    my $outfile  = catfile ($pdb, "$name1.$name2.hhalign.out");

    my $cmd = "$hhalign -i $hhmfile1 -t $hhmfile2 -o $outfile";
    system $cmd;

    open (TMPFILE, "$outfile") or croak "No hhalign output file $outfile";
        my $ll;
        for (my $tt=0; $tt<10; $tt++) {
            $ll = <TMPFILE>;
        }
    close (TMPFILE);

        if (-e $outfile)  {unlink $outfile};
        if (-e $hhmfile1) {unlink $hhmfile1};
        if (-e $hhmfile2) {unlink $hhmfile2};

        my @ln = split (/\s+/, $ll);
        my $prob = $ln[3];
        my $evalue = $ln[4];
        #print "$evalue\t$prob\n";
    return $evalue;
}

=head2 match_in_array

Subroutine to find if a scalar element appears in an array

=cut

sub match_in_array {

    my ($query,@array)=@_;

    croak "Query string is required" unless $query;
    croak "Array to compare is required" unless @array;
    
    foreach (@array) {
        if ($query eq $_) {return 1}
    }
    return 0;
}

=head2 trim

Trim function to remove whitespace from the start and end of the string

=cut

sub trim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

=head2 ltrim

Left trim function to remove leading whitespace

=cut

sub ltrim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    return $string;
}

=head2 rtrim

Right trim function to remove trailing whitespace

=cut

sub rtrim($) {
    my $string = shift;
    $string =~ s/\s+$//;
    return $string;
}

=head2 get_hhm

Subroutine to carry out HHblits and generate HMM for a sequence without adding SS info from DSSP or PSIPRED

=cut

sub get_hhm {
        my ($pdb,$name,$seq) = @_;

        croak "4-letter pdb code is required"      unless $pdb;
        croak "Name of sequence file is required"  unless $name;
        croak "Sequence is required"               unless $seq;

        my $seqfile = catfile ($pdb, "$name.seq");

        open (SEQFILE, ">$seqfile") or croak "unable to open file $name.seq to write sequence";
            print SEQFILE ">$name\n";
            print SEQFILE "$seq\n";
        close (SEQFILE);

        my $hhblits    = catfile ($HHSUITE_PATH, $HHBLITS_EXEC);
        my $hhblits_db = catfile ($HHBLITS_DB_PATH, $HHBLITS_DB);
        my $outfile1   = catfile ($pdb, "$name.a3m");
        my $cmd = "$hhblits -i $seqfile -d $hhblits_db -oa3m $outfile1 -e 100 -n 2";
        system $cmd;

        my $hhmake     = catfile ($HHSUITE_PATH, $HHMAKE_EXEC);
        my $outfile2   = catfile ($pdb, "$name.hhm");
        my $outfile3   = catfile ($pdb, "$name.hhr");
        my $cmd2 = "$hhmake -i $outfile1 -o $outfile2";
        system $cmd2;

        if (-e $seqfile)  {unlink $seqfile};
        if (-e $outfile1) {unlink $outfile1};
        if (-e $outfile3) {unlink $outfile3};
}

=head2 read_dd_info

Subroutine to read the information from the dynamic database

=cut

#Subroutine to read the dynamic database file
sub read_dd_info {
    my ($dd_file) = @_;
    croak "Dynamic Database input file name is required" unless $dd_file;

        open(DDFILE,$dd_file) or croak "No dd_info input file";;
        my @ddlist;

        while (my $dd_entry = <DDFILE>) {
                chomp $dd_entry;
                push (@ddlist, $dd_entry);
                #print "$dd_entry\n";
        }
        close(DDFILE);
    return (@ddlist);
}

=head1 AUTHORS

Fiserlab memebers, C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CompareSmotifs

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

1; # End of CompareSmotifs
