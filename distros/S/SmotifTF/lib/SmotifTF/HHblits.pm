package SmotifTF::HHblits;

use 5.8.8 ;
use strict;
use warnings;

use constant DEBUG => 0;
use Carp;
use Proc::Simple;
use Config::Simple;

use File::Spec::Functions qw(catfile catdir);
use SmotifTF::GeometricalCalculations;

=head1 NAME

HHblits 

=head1 VERSION

Version 0.01 

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Set of routines to run and analyze HHblits.

=cut

my $config_file = $ENV{'SMOTIFTF_CONFIG_FILE'};
croak "Environmental variable SMOTIFTF_CONFIG_FILE should be set"
  unless $config_file;
my $cfg = new Config::Simple($config_file);

my $psipred      = $cfg->param( -block => 'psipred' );
my $PSIPRED_PATH = $psipred->{'path'};
my $PSIPRED_EXEC = $psipred->{'exec'};

my $hhsuite          = $cfg->param( -block => 'hhsuite' );
my $HHBLITS_PATH     = $hhsuite->{'path'};
my $HHBLITS_EXEC     = $hhsuite->{'hhblits'};
my $HHBLITS_DB_PATH  = $hhsuite->{'db_path'};
my $HHSEARCH_EXEC    = $hhsuite->{'hhsearch'};
my $CONTEXT_DATA_LIB = $hhsuite->{'cs'};
my $HHSUITE_PATH     = $hhsuite->{'path'};
my $NR_HHM_DB        = $hhsuite->{'nr_hhm_db'};
my $PDB_HHM_DB       = $hhsuite->{'pdb_hhm_db'};

=head2 run
   run hhblits
   
   input: sequence, sequence fasta file 
          database, database  

=cut

sub run_hhblits {
    use Proc::Simple;

    my %args = ( 
        sequence_fasta  => '',
        directory       => '',
        database        => '',
        oa3m            => '',
        ohhm            => '',
        @_,
    );
    my $sequence  = $args{'sequence_fasta'}  || undef;
    my $directory = $args{'directory'}       || "./";
    my $database  = $args{'database'}        || 'nr20_12Aug11';
    my $oa3m      = $args{'oa3m'}        || 'test.a3m';
    my $ohhm      = $args{'ohhm'}        || 'test.hhm';

    croak "sequence in fasta format is required" 
        unless $sequence;
    croak "database is required" unless $database;

    croak "$sequence does not exists on $directory" 
        unless -e "$directory/$sequence";

    my $myproc = Proc::Simple->new();

    my $log_file  = "$directory/hhblits_log.txt";
    my $error_file= "$directory/hhblits_err.txt";

    chdir $directory;   
    my $hhblits = catfile( $HHBLITS_PATH, $HHBLITS_EXEC );   
   
    my $cmd = "hhblits -i $sequence -d /usr/local/databases/hhsuite_dbs/$database -psipred /usr/local/bio/psipred/bin/psipred -psipred_data /usr/local/bio/psipred/data/ -oa3m $oa3m -ohhm $ohhm -M 50 -e 1e-3 -n 1 -p 20 -Z 100 -B 100 -seq 1 -aliw 80 -local -norealign -cov 0";
    
    my $status = $myproc->start( "$cmd" );

    # Wait until process is done
    my $exit_status = $myproc->wait();

    if ( $exit_status == 0 ){
        return 1; 
    }
    die "hhblits failed. Check $log_file and $error_file";    

}

#=head2
#
#=cut
sub run_search {
    use Proc::Simple;

    my %args = ( 
        sequence_hhm  => '',
        directory  => '',
        database   => '',
        ohhr => '',
        @_,
    );
    my $sequence_hhm = $args{'sequence_hhm'}  || undef;
    my $directory    = $args{'directory'}     || "./";
    my $database     = $args{'database'}      || 'pdb70_06Sep14_hhm_db';
    my $ohhr         = $args{'ohhr'}          || 'test_hhs.hhr';

    croak "sequence in hhm format is required" 
        unless $sequence_hhm;
    
    croak "database is required" unless $database;
    
    croak "$sequence_hhm does not exists on $directory" 
        unless -e "$directory/$sequence_hhm";

    my $myproc = Proc::Simple->new();
    
    chdir $directory;   
    my $log_file  = "$directory/hhsearch_log.txt";
    my $error_file= "$directory/hhsearch_err.txt";
   
    $myproc->redirect_output($log_file, $error_file);
   
    my $cmd = "hhsearch -i $sequence_hhm -d /usr/local/databases/hhsuite_dbs/$database -p 20  -P 20 -Z 100 -B 100 -seq 1 -aliw 80 -local -ssm 2 -norealign -sc 1 -dbstrlen 10000 -cs /usr/local/bio/hh/hhsuite-2.0.16/data/context_data.lib -o $ohhr";
    
    my $status = $myproc->start( "$cmd" );

    # Wait until process is done
    my $exit_status = $myproc->wait();

    if ( $exit_status == 0 ){
        return 1; 
    }
    die "hhsearch failed. Check $log_file and $error_file";    

}

#=head2 format_hhr_file
#
#=cut

sub format_hhr_file_old {
    my ($file1, $pdba, $code, $aref_hitlist) = @_;
    
    die "HHR file is required" unless $file1;
    die "HHR pdba is required" unless $pdba;
    die "HHR code is required" unless $code;
    #die "HHR file is required" unless @hitlist;
  
    die "HHR output files does not exists" 
        unless -e $file1;

    my $infile;
    open $infile, '<', $file1 or die $!;

    # get e_value, pdb code and chain fromn hhr out file
    my @pdb_chain_evalue;
    while (my $line = <$infile>) {
        chomp $line;
        
        next unless ($line =~ /^\s+[0-9]+/);
        
        my $evalue = substr ($line, 41, 7);
        $evalue =~ s/^\s+// if $evalue;
    
        my $p     = substr ($line, 4, 4);
        my $pdb   = lc $p if $p;
        
        my $c     = substr ($line, 9, 1);
        my $chain = uc $c if $c;

        next if ($pdb eq $pdba);
   
        print "$pdb\t$chain\t$evalue\n" if DEBUG;
        my @tmp;
        push @tmp, $pdb;
        push @tmp, $chain;
        push @tmp, $evalue;

        push @pdb_chain_evalue, \@tmp;
    }    
    close $infile;

    # use Data::Dumper;
    # print Dumper(\@pdb_chain_evalue);
    # print Dumper($aref_hitlist);
    # return;
=for
1 = pdb hit (sequence hit)
2 = chain
3 = evalue
4 = method 

2grk    A       2.0     DEL
2pmz    F       2.2     DEL
4ak4    B       4.4     HHS
4hqe    A       4.9     DEL
3sc0    A       5.9     HHS
=cut
   use Data::Dumper;
   foreach my $pdb_chain_evalue (@pdb_chain_evalue) {
        print Dumper(\$pdb_chain_evalue);
        my $pdb   = $pdb_chain_evalue->[0];
        my $chain = $pdb_chain_evalue->[1];
        my $evalue= $pdb_chain_evalue->[2];

        print Dumper(\@$aref_hitlist);
=for        
        foreach my $aref (@$aref_hitlist) {
            my $pdb_hit   = $aref->[0];
            my $chain_hit = $aref->[1];
            my $evalue_hit= $aref->[2];
            my $method_hit= $aref->[3];

            if ($pdb eq $pdb_hit && $chain eq $chain_hit) {
                    if ( $evalue >= $evalue_hit) {
                        next;
                    } else {
                        $aref->[2] = $evalue;
                        $aref->[3] = $code;
                    }
                }
        }
=cut        
        #push @{$hitlist[$num]},$pdb,$chain,$evalue,$code;
        push @{$aref_hitlist}, $pdb,$chain,$evalue,$code;
    }
    #return ($num, @hitlist);
}

sub format_hhr_file {
    my ($dir, $file1, $pdba, $num, $code, @hitlist) = @_;
    
    die "HHR file is required" unless $file1;
    die "HHR pdba is required" unless $pdba;
    die "HHR num  is required" unless defined $num;
    die "HHR code is required" unless $code;
    #die "HHR file is required" unless @hitlist;
    
    $dir = "./" unless $dir;
  
   $file1 = catfile( $dir, $file1 );
   
   die "HHR output files does not exists" 
        unless -e  $file1 ;

    my $infile;
    open $infile, '<', $file1 or die $!;

    WLOOP:while (my $line = <$infile>) {
        chomp $line;
        my $lin = $line;
        $lin =~ s/^\s+//;
    
        next unless ($lin =~ /^[0-9]/);
        
        my $evalue = substr ($line, 41, 7);
        $evalue =~ s/^\s+// if $evalue;
    
        my $p     = substr ($line, 4, 4);
        my $pdb   = lc $p if $p;
        
        my $c     = substr ($line, 9, 1);
        my $chain = uc $c if $c;

        next if ($pdb eq $pdba);
   
        print "$pdb\t$chain\t$evalue\n" if DEBUG;
        for (my $aa=0; $aa<scalar(@hitlist); $aa++) {
             if ($pdb eq $hitlist[$aa][0] && $chain eq $hitlist[$aa][1]) {
                    if ( $evalue >= $hitlist[$aa][2] ) {
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

    close $infile;
    return ($num, @hitlist);
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
    open(FH, $file) or die "cannot opne $file";
    
    my %ppred;
    while (my $line = <FH>) {
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
    close FH;
    return %ppred;
}



=head1 AUTHORS

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HHblits

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

1; # End of HHblits
