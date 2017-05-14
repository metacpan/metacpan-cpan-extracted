package SmotifTF::Psiblast;

use 5.8.8 ;
use strict;
use warnings;

use Carp;
use File::Spec::Functions qw(catfile catdir);

=head1 NAME

Psiblast 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


my $config_file = $ENV{'SMOTIFTF_CONFIG_FILE'};
croak "Environmental variable SMOTIFTF_CONFIG_FILE should be set"
  unless $config_file;

my $cfg = new Config::Simple($config_file);
my $psiblast      = $cfg->param( -block => 'psiblast' );
my $PSIBLAST_PATH = $psiblast->{'path'};
my $PSIBLAST_EXEC = $psiblast->{'exec'};
my $DB_PATH       = $psiblast->{'db_path'};

my $deltablast    = $cfg->param( -block => 'deltablast' );
my $DELTABLAST_PATH = $deltablast->{'path'};
my $DELTABLAST_EXEC = $deltablast->{'exec'};
my $DELTA_DB_PATH   = $deltablast->{'db_path'};


=head1 SYNOPSIS

Set of routines to run and analyze PsiBlast.

=cut

sub format_blast_file {
	 my ($dir, $file1, $pdba, $num, $code, @hitlist) = @_;
	 
     die "file is required" unless $file1;
	 die "pdba is required" unless $pdba;
	 die "num  is required" unless defined $num;
	 die "code is required" unless $code;
     $dir = "./" unless $dir;
  
    die "HHR output files does not exists" 
        unless -e catfile( $dir, $file1 );
	 #die "" unless @hitlist;

     die "Blast output file does not exist" 
        unless  -e catfile( $dir, $file1 );
  
     my $full_path_name = catfile( $dir, $file1 );
     my $infile;
	 open $infile, '<', $full_path_name or die $!;
	 WLOOP:while (my $line = <$infile>) {
	  	chomp $line;
	  	
        my @lin = split(/\s+/, $line);
		my $evalue = $lin[-2];
	  	if (scalar(@lin)==12 && $evalue<10) {
			my @ll = split( /\|/, $lin[1] );
			#print "@ll\n";
			my $pdb   = lc $ll[3];
			my $chain = uc $ll[4];
		    next WLOOP	if ($pdb eq $pdba);

			for (my $aa=0; $aa<scalar(@hitlist); $aa++) {
				if ($pdb eq $hitlist[$aa][0] && $chain eq $hitlist[$aa][1]) {
					if ($evalue >= $hitlist[$aa][2]) {
						next WLOOP;
					} else {
						$hitlist[$aa][2] = $evalue;
						$hitlist[$aa][3] = $code;
						next WLOOP;
					}
				}  
			}
			push @{$hitlist[$num]},$pdb,$chain,$evalue,$code;
			$num++;
 	  	}
	  }
	  close $infile;
	  return ($num, @hitlist);
}


=head2 run_psiblast
   
   run_psiblast
   Routine to run psiblast locally.
   
   input:
   query, file cotaining sequence in fasta format
   directory, where to save psiblast output files
   database, to run search against it.

=cut

sub run_psiblast {
    use Proc::Simple;

    my %args = ( 
        query          => '',
        directory      => '',
        database       => '',
        out            => '',
        evalue         => '',
        num_iterations => '',
        @_,
    );
    my $query         = $args{'query'}          || undef;
    my $directory     = $args{'directory'}      || "./";
    my $database      = $args{'database'}       || 'pdbaa';
    my $out           = $args{'out'}            || undef;
    my $evalue        = $args{'evalue'}         || 100;
    my $num_iterations= $args{'num_iterations'} || 2;

    croak "query is required"    unless $query;
    croak "database is required" unless $database;
    croak "out  is required"     unless $out;

    croak "query $directory/$query does not exists"
        unless -e catfile($directory, $query);

    my $log_file  = "$directory/psiblast_log.txt";
    my $error_file= "$directory/psiblast_err.txt";
   
    my $myproc = Proc::Simple->new();
    $myproc->redirect_output($log_file, $error_file);
     
    chdir $directory;
    # my $cmd =  "/usr/local/bio/blast+/bin/psiblast -query $query -db /usr/local/databases/blast/$database -out $out -outfmt 6 -evalue $evalue -num_iterations $num_iterations";
    
    my $PSIBLAST = catfile( $PSIBLAST_PATH, $PSIBLAST_EXEC );
    my $DB       = catfile( $DB_PATH, $database );
    my $cmd =  "$PSIBLAST -query $query -db $DB -out $out -outfmt 6 -evalue $evalue -num_iterations $num_iterations";
    #print "cmd = $cmd\n";

    my $status = $myproc->start( "$cmd" );

    # Wait until process is done
    my $exit_status = $myproc->wait();

    if ( $exit_status == 0 ){
        return 1; 
    }
    die "psiblast failed. Check $log_file and $error_file";    

}

=head2 run_deltablast
   
   run_deltablast
   Routine to run deltablast locally.
   
   input:
   query, file cotaining sequence in fasta format
   directory, where to save psiblast output files
   database, to run search against it.

=cut

# system "/usr/local/bio/blast+/bin/deltablast -query $fasta_file -db /usr/local/databases/blast/pdbaa -out $file2 -outfmt 6 -evalue 100";
sub run_deltablast {
    use Proc::Simple;

    my %args = ( 
        query          => '',
        directory      => '',
        database       => '',
        out            => '',
        evalue         => '',
        @_,
    );
    my $query         = $args{'query'}          || undef;
    my $directory     = $args{'directory'}      || "./";
    my $database      = $args{'database'}       || 'pdbaa';
    my $out           = $args{'out'}            || undef;
    my $evalue        = $args{'evalue'}         || 100;

    croak "query is required"    unless $query;
    croak "database is required" unless $database;
    croak "out  is required"     unless $out;
    
    die "query does not exist" 
        unless ( -e "$directory/$query" );

    my $log_file  = "$directory/deltablast_log.txt";
    my $error_file= "$directory/deltablast_err.txt";
   
    my $myproc = Proc::Simple->new();
    $myproc->redirect_output($log_file, $error_file);
   
    chdir $directory;
    #my $cmd =  "/usr/local/bio/blast+/bin/deltablast -query $query -db /usr/local/databases/blast/$database -out $out -outfmt 6 -evalue $evalue";
    
    my $DELTA_BLAST = catfile( $DELTABLAST_PATH, $DELTABLAST_EXEC);
    my $DB          = catfile( $DELTA_DB_PATH, $database );
    
    my $cmd =  "$DELTA_BLAST -query $query -db $DB -out $out -outfmt 6 -evalue $evalue";
    my $status = $myproc->start( "$cmd" );

    # Wait until process is done
    my $exit_status = $myproc->wait();

    if ( $exit_status == 0 ){
        return 1; 
    }
    die "deltablast failed. Check $log_file and $error_file";    

}


=head1 AUTHORS

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Psiblast

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

1; # End of Psiblast
