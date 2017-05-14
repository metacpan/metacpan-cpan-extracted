package SmotifTF::Psipred;

# use v5.8.8;
use strict;
use warnings;

use File::Spec::Functions qw(catfile catdir);
use SmotifTF::GeometricalCalculations;
use Carp;
use Proc::Simple;
use Data::Dumper;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = "0.01";

    @ISA = qw(Exporter);

    # name of the functions to export
    @EXPORT = qw(
      run
      analyze_psipred
      parse
      write_outfile
      count_smotifs
      count_pdb_smotifs
    );

    @EXPORT_OK = qw(
      split_ss_string
      getFirstResidueNumber
      );    # symbols to export on request
}

our @EXPORT_OK;

use Config::Simple;
my $config_file = $ENV{'SMOTIFTF_CONFIG_FILE'};
croak "Environmental variable SMOTIFTF_CONFIG_FILE should be set"
  unless $config_file;
my $cfg = new Config::Simple($config_file);

my $psipred      = $cfg->param( -block => 'psipred' );
my $PSIPRED_PATH = $psipred->{'path'};
my $PSIPRED_EXEC = $psipred->{'exec'};

use constant SMOTIFS_NUMBER_UPPER_LIMIT => 14;
use constant SMOTIFS_NUMBER_LOWER_LIMIT => 2;

=head1 NAME

Psipred

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

	Set of routines to run and analyze Psipred

	Usage: 

    use Psipred;

    run ($sequence, $directory);
    analyze_psipred ($pdb, $chain, $directory, $havestructure);

=cut

=head2 run

   run psipred
   /usr/local/bin/runpsipred 4wyq.fasta
   
=cut

sub run {
    use Proc::Simple;

    my %args = ( 
        sequence  => '',
        directory => '',
        @_,
    );
    my $sequence  = $args{'sequence'}  || undef;
    my $directory = $args{'directory'} || "./";

    croak "sequence in fasta format is required" unless $sequence;

    my $myproc = Proc::Simple->new();

    my $log_file  = "$directory/psipred_log.txt";
    my $error_file= "$directory/psipred_err.txt";
    $myproc->redirect_output($log_file, $error_file);

    chdir $directory;    
    my $runpsipred = catfile( $PSIPRED_PATH, $PSIPRED_EXEC );   
    my $status = $myproc->start( "$runpsipred", $sequence );
 
    # Wait until process is done
    my $exit_status = $myproc->wait();

    return $exit_status;

}


=head2 analyze_psipred

It will return the secondary structure prediction and sequence
from psipred output file.

Script to get the Smotif defintions from PSIPRED output

INPUT ARGUMENTS:
1) $pdb : pdb code (the PSIPRED output file should be in the subdirectory identified by the pdb code e.g. 1ptf/1ptf.horiz)
2) $chain : chain ID
3) If structure exists, 1, else, 0. 

INPUT FILES:
In the <pdbcode> folder:
1)<pdbcode>/<pdbcode>.horiz (PSIPRED output file)
2)<pdbcode>/pdb<pdbcode><chain>.ent (PDB file), if structure exists. 

OUTPUT FILES:
In the <pdbcode> folder:
<pdbcode>.out :File with smotif information: Protein code, Chain, Smotif type, Smotif start residue, Loop length, Length of first secondary structure, Length of second secondary structure, Sequence

=cut

sub analyze_psipred {
	
    my %args = (
        pdb       => '',
        chain     => '',
        directory => '',
        havestructure => '',
        @_,
    );
    my $pdb          = $args{'pdb'}           || undef;
    my $chain        = $args{'chain'}         || 'A';
    my $directory    = $args{'directory'}     || "./";
    my $havestructure= $args{'havestructure'} || 0;
    
    croak "pdb_id is required" unless $pdb;
    
    my %psipred = parse("$directory/$pdb.horiz");
    
    #print Dumper(\%psipred);   
 
    croak "Error processing psipred out files. Pred was not found." 
        unless exists $psipred{"Pred"};
    
    croak "Error processing psipred out files. AA was not found." 
        unless exists $psipred{"AA"};
    
    my $sslist = $psipred{"Pred"};
    my $seq    = $psipred{"AA"};

    my $start = 0;  #Initialize start residue
    my @ss = split_ss_string( $sslist, \$start);	

    # use Data::Dumper;
    # print Dumper(\@ss);

    # find actual start residue in pdb file, if structure exists
    my $shiftindex = 1;
    if ($havestructure == 1) {
        my $localpdb = SmotifTF::GeometricalCalculations::get_full_path_name_for_pdb_code($pdb, $chain);
        unless (-e $localpdb) {croak "PDB structure file missing for $pdb $chain"};
        $shiftindex = getFirstResidueNumber($localpdb);
    }		
   
    # Print smotif information to $pdb/$pdb.out file
    $start = $start + $shiftindex;
    my $filename = catfile ($directory, "$pdb.out");
    write_outfile ($pdb,$chain,$filename,$start,$seq,@ss);

    # Check the number of Smotifs in the Query protein
    my $num_motifs = count_smotifs ($filename);
    
    # print "Returning num_motifs = $num_motifs\n"; 
    return ($seq, $num_motifs);
}

=head2 write_outfile
    
    Writes the smotif definitions obtained from Psipred to the $pdb/$pdb.out file

    Input: $filename, $seq, @ss
    This is the most important file and has to named $pdb/$pdb.out
    and the format of this file is 
    print OUTFILE "Name\tChain\tType\tStart\tLooplength\tSS1length\tSS2length\tSequence\n";

=cut
    
sub write_outfile {
        
    my ($pdb,$chain,$filename,$start,$seq,@ss) = @_;    
    
    croak "4-letter pdb code is required" unless $pdb;
    # croak "Chain ID is required"          unless $chain;
    croak "Output filename is required"   unless $filename;
    croak "Protein sequence is required"  unless $seq;
    croak "SS array is requires"          unless @ss;
    croak "Smotif start residue number is required"       unless $start;
    
    # Query chain-name is not manadatory for calculation further down.
    # That's why we set it to A by default.   
    $chain = 'A' unless defined $chain;

    open(OUTFILE,">$filename");	
    print OUTFILE "Name\tChain\tType\tStart\tLooplength\tSS1length\tSS2length\tSequence\n";
    for (my $aa=0;$aa<(scalar(@ss)-1)/2;$aa++) {
        print OUTFILE "$pdb";
        print OUTFILE ".pdb\t$chain\t";
        print OUTFILE $ss[$aa*2][0];
        print OUTFILE $ss[$aa*2+2][0];
        print OUTFILE "\t",$start,"\t";
        print OUTFILE scalar(@{$ss[$aa*2+1]}),"\t";
        print OUTFILE scalar(@{$ss[$aa*2]}),"\t";
        print OUTFILE scalar(@{$ss[$aa*2+2]}),"\t";
        my $len=scalar(@{$ss[$aa*2]})+scalar(@{$ss[$aa*2+1]})+scalar(@{$ss[$aa*2+2]});
        print OUTFILE substr($seq,$start,$len),"\n";
        $start+=scalar(@{$ss[$aa*2]})+scalar(@{$ss[$aa*2+1]});
    }	
    close(OUTFILE);

}

=head2 split_ss_string

SUBROUTINE to convert a series of secondary structure types to a list of start and end points for smotifs
#Input 1: $ss - a string of secondary structure types, 
	where H=alpha helix and E=strand e.g. (HHHHLLLLEEEE)
#Input 2: $startpos - residue at which first smotif begins

=cut
sub split_ss_string {
	my ($ss, $startpos) = @_;

    croak "secondary structure string is needed" unless $ss;
    croak "start position is not defined" unless defined $startpos;

    my @ss = split(//, $ss);
    # convert all non-helix/non-strand positions to 'L'
	foreach (@ss) {
		if ( (($_) ne 'H') and (($_) ne 'E') ) {
			$_='L'
        }
    }
	
    # convert strands/helices less than 2 residues long into loops
	my $sslength = 1;
	my $prev = $ss[0];
	for (my $count=1; $count<scalar(@ss); $count++) {
		if ($ss[$count] eq $prev) {
			$sslength++;
		} else {
			if ((($sslength<2) and ($prev ne 'L')) or (($sslength<4) and ($prev eq 'H'))) {
				for (my $aa = $count-$sslength; $aa<$count; $aa++) {
                    $ss[$aa]='L'
                };
			}
			$prev    = $ss[$count];
			$sslength= 1;
		}
	}
	my @out;
	my $start = 0;
	for (my $aa=0; $aa<scalar(@ss)-1; $aa++) {
		if ($ss[$aa] ne $ss[$aa+1]) {		#switch in secondary structure type implies a landmark
			push( @out,[@ss[$start..$aa]]);
			if (($ss[$aa] ne 'L') and ($ss[$aa+1] ne 'L')) {
                $ss[$aa+1] = 'L';
            }
			$start = $aa + 1;
		}
	}
	if ($out[0][0] eq 'L') {
		$$startpos = scalar(@{$out[0]});
		shift(@out);
	}
	if ($out[-1][0] eq 'L') {
        pop(@out)
    };
	return @out;
}

=head2 getFirstResidueNumber

Subroutine to get starting residue number of a pdb file

=cut

sub getFirstResidueNumber {

    my ($localpdb) = @_;

    croak "PDB file name is required" unless $localpdb;
	
    my $resno = 1;
    open PDB, "<$localpdb";
    WLOOP: while (my $line = <PDB>) {
        chomp $line;
        #print "$line\n";
        if ($line =~ /^ATOM/) {
            $resno = substr($line, 22, 5); $resno =~ s/\s+//g;
            last WLOOP;
        } elsif ($line =~ /^HETATM/) {
            $resno = substr($line, 22, 5); $resno =~ s/\s+//g;
            last WLOOP;
        }
    }
    $resno = 1 if ($resno =~ /[a-zA-Z]/);

    close PDB;
    return $resno;
}

=head2 parse

It returns a hash containing the following keys:
$VAR1 = {
    'AA'   => 'MNLQPIFWIGLISSVCCVF...'
    'Conf' => '9975402235541123446...'
    'Pred' => 'CCCCCCHHHHHHHCEEEEE...'
};

=cut
sub parse  {
    
    my ($file) = @_;
    
    chomp $file if $file; 
    
    open my $fh, "<".  $file 
		or die "cannot open $file $!";
    
    croak "$file does end in .horiz" 
        unless $file =~ m/\.horiz$/; 

    my %ppred;
    while (my $line = <$fh>) {
        if ($line =~ /^Conf:/) {
                $line =~ s/^Conf://g;
                $line =~ s/\s+//g;
                if ( exists($ppred{'Conf'}) ){
                    $ppred{'Conf'} .= $line;
                }
                else {
                    $ppred{'Conf'} = $line;
                }
        } 
        if ($line =~ /^Pred:/) {
                $line =~ s/^Pred://g;
                $line =~ s/\s+//g;
                if ( exists($ppred{'Pred'}) ){
                    $ppred{'Pred'} .= $line;
                }
                else {
                    $ppred{'Pred'} = $line;
                }
        } 
        if ($line =~ /^\s+AA:/) {
                $line =~ s/^\s+AA://g;
                $line =~ s/\s+//g;
                if ( exists($ppred{Conf}) ){
                    $ppred{'AA'} .= $line;
                }
                else {
                    $ppred{'AA'} = $line;
                }
        } 
    }
    close $fh;
    return %ppred;
}

=head2 count_smotifs

Subroutine to count the number of Smotifs in a given Smotif definition file (typically $pdb/$pdb.out). 
Input : Filename with Smotif definition
Output: Returns the number of Smotifs in the given file

=cut

sub count_smotifs {

    my ($filename) = @_;
    
    # print "opening $filename ...\n";
    open(INFILE, $filename) or croak "Unable to open Smotif definition file $filename\n";
    my $smotifs = 0;
    my $line = <INFILE>;      #skip header line
    while (my $line = <INFILE>) {
        chomp $line;
        my @lin = split (/\s+/,$line);
        # print Dumper(\@lin); 
        croak "Unrecognized file format in $filename\n"
            if not (scalar(@lin) == 8);
        $smotifs++;
    }
    close (INFILE);
    # print "smotifs = $smotifs\n";
    return $smotifs;
}

=head2 count_pdb_smotifs

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

        croak "$filename does not exists. First run 'Psipred' step 1."
        unless ( -e $filename );

        my $smotifs = count_smotifs( $filename );
        return $smotifs;
}

=head1 AUTHORS

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-./ at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=./>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Psipred

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=./>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/./>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/./>

=item * Search CPAN

L<http://search.cpan.org/dist/.//>

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

1; # End of Psipred
