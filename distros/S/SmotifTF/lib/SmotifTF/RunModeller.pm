package SmotifTF::RunModeller;

use 5.8.8 ;
use strict;
use warnings;

use File::Spec::Functions qw(catfile catdir);
use SmotifTF::Protein;
use SmotifTF::Psipred;
use SmotifTF::EnumerateSmotifCombinations;
use Data::Dumper;
use File::Copy;
use Carp;
use Cwd;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
    $VERSION = "0.01";

    @ISA = qw(Exporter);

    #Name of the functions to export
    @EXPORT = qw(
      get_model
    );

    #Name of the functions to export on request
    @EXPORT_OK = qw();
}

use constant DEBUG => 0;
our @EXPORT_OK;
use Config::Simple;
my $config_file = $ENV{'SMOTIFTF_CONFIG_FILE'};
croak "Environmental variable SMOTIFTF_CONFIG_FILE should be set"
  unless $config_file;
my $cfg = new Config::Simple($config_file);

my $modeller      = $cfg->param( -block => 'modeller' );
my $MODELLER_PATH = $modeller->{'path'};
my $MODELLER_EXEC = $modeller->{'exec'};

=head1 NAME

RunModeller

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module is the last step of the modeling algorithm.
It runs modeller for the top 5 scoring models obtained from enumeration 
to fix the sidechains and the stereochemistry. 

    use RunModeller;

    get_model($pdbcode);

=head1 EXPORT

    get_model

=head2 get_model

    Subroutine to run modeller. 
    Input: 4-letter pdbcode, flag for whether native structure is available (0=No, 1=yes). 
    Output files: Top 5 models in the pdb directory with filenames Model.1.pdb, Model.2.pdb, 
                  Model.3.pdb, Model.4.pdb, Model.5.pdb
    On screen output: Information on completed models.

=cut

sub get_model {

    my ($pdbcode) = @_;

    croak "4-letter pdb code is required" unless $pdbcode;

    #Obtain the number of Smotifs in the query
    # my $filename = "$pdbcode/$pdbcode.out";
    my $filename = catfile( $pdbcode, "$pdbcode" . '.out' );
    my $nummots = SmotifTF::Psipred::count_smotifs($filename);

    my $nummods = 0;
    my @best;

    #Obtain information on the Smotifs contributing to the best scoring models
    # my $filename2 = "$pdbcode/$pdbcode\_ranked_refined.csv";
    my $filename2 = catfile( $pdbcode, "$pdbcode" . '_ranked_refined.csv' );

    #print "REading $filename2\n";
    open( my $infile, "<", $filename2 )
      or croak "Unable to open ranking file $filename2 $1";
    while ( my $line = <$infile> ) {
        chomp $line;
        my @bes = split( /\s+/, $line );

        $nummods++;
        for ( my $bb = $nummots ; $bb < 2 * $nummots ; $bb++ ) {
            push( @best, $bes[$bb] );
        }
    }
    close $infile;

    #Choose only top 5 ranked models
    my $numm;
    if ( $nummods < 5 ) {
        $numm = $nummods;
    }
    else {
        $numm = 5;
    }

    #For the top 5 best scoring models, prepare to run modeller
    for ( my $ba = 1 ; $ba <= $numm ; $ba++ ) {
        my $count;
        my @smotlist;
        for (
            $count = ( $ba * $nummots ) - $nummots ;
            $count < $ba * $nummots ;
            $count++
          )
        {
            push( @smotlist, $best[$count] );
        }

        #Generate test structure
        my $test = SmotifTF::Protein->new();
        my @data;
        my $line;
        open( INFILE, $filename ) or croak "Unable to open file $filename\n";
        $line = <INFILE>;    #skip header line
        my $aa = 0;
        my $seq;
        my @lin;

        while ( my $line = <INFILE> ) {
            @lin = split( '\s+', $line );
            push(
                @data,
                [
                    (
                        $pdbcode, $lin[1], $lin[3], $lin[5],
                        $lin[6],  $lin[4], 0,       $lin[2]
                    )
                ]
            );

            # use Data::Dumper;
            # print Dumper($smotlist[$aa]);

            my @ddlist = SmotifTF::EnumerateSmotifCombinations::get_dd_info($pdbcode,$smotlist[$aa]);
                
            $test->add_motif(@ddlist);

            my @lm = $test->one_landmark(-1);
            if ( $aa == 0 ) {
                if ( $lm[1] < $data[0][3] ) {
                    $test->elongate( 0, $data[0][3] - $lm[1] );
                }
                if ( $lm[1] > $data[0][3] ) {
                    $test->shorten( 0, $lm[1] - $data[0][3] );
                }
            }
            if ( $lm[3] - $lm[1] < $data[$aa][4] + $data[$aa][5] ) {
                $test->elongate( -1,
                    $data[$aa][4] + $data[$aa][5] - $lm[3] + $lm[1] );
            }
            if ( $lm[3] - $lm[1] > $data[$aa][4] + $data[$aa][5] ) {
                $test->shorten( -1,
                    $lm[3] - $lm[1] - $data[$aa][4] - $data[$aa][5] );
            }
            $aa++;
            $seq .= substr( $lin[7], 0, $lin[4] + $lin[5] );
        }
        $seq .= substr( $lin[7], $lin[4] + $lin[5], $lin[6] );
        close(INFILE);
        $test->{seq} = $seq;
        $test->add_amide_hydrogens();

# $test->print_to_file("$pdbcode/1tmp.pdb"); #print the backbone generated to a file
        my $pdbcode_1tmp_pdb = catfile( "$pdbcode", '1tmp.pdb' );
        $test->print_to_file("$pdbcode_1tmp_pdb")
          ;    #print the backbone generated to a file

#Get the alignment file for modeller
# open(OUTFILE,">$pdbcode/1tmpalign.ali") or croak "Unable to open alignment file for $pdbcode\n";
        my $pdbcode_1tmpalign_ali = catfile( $pdbcode, '1tmpalign.ali' );
        open( OUTFILE, ">$pdbcode_1tmpalign_ali" )
          or croak "Unable to open alignment file for $pdbcode $!";

        print OUTFILE
          'C; A sample alignment in the PIR format; used in tutorial', "\n";
        print OUTFILE ">P1;1tmp\n";
        print OUTFILE 'structureX:1tmp:1:A :', length($seq),
          ':A :temp1:organism1: 1.90: 0.19', "\n";
        for ( my $aa = 0 ; $aa < length($seq) / 60 ; $aa++ ) {
            print OUTFILE substr( $seq, $aa * 60, 60 );
            if ( $aa * 60 + 60 >= length($seq) ) { print OUTFILE '*' }
            print OUTFILE "\n";
        }
        print OUTFILE ">P1;1aaa\n";
        print OUTFILE 'sequence:1aaa:', 1, ':A :', length($seq),
          ':A :temp1:organism1: 1.90: -1.00', "\n";
        for ( my $aa = 0 ; $aa < length($seq) / 60 ; $aa++ ) {
            print OUTFILE substr( $seq, $aa * 60, 60 );
            if ( $aa * 60 + 60 >= length($seq) ) { print OUTFILE '*' }
            print OUTFILE "\n";
        }
        close(OUTFILE);

#Get the python script for modeller
# open(OUTFILE,">$pdbcode/1tmprelax.py") or croak "Unable to open python script file for $pdbcode\n";
        my $pdbcode_1tmprelax_py = catfile( $pdbcode, '1tmprelax.py' );
        open( OUTFILE, ">$pdbcode_1tmprelax_py" )
          or croak "Unable to open python script file for $pdbcode\n";

        print OUTFILE "from modeller import *\n";
        print OUTFILE "from modeller.automodel import *\n";
        print OUTFILE "log.verbose()\n";
        print OUTFILE "env = environ()\n";
        print OUTFILE "env.io.atom_files_directory = ['.', '../atom_files']\n";
        print OUTFILE "class MyModel(automodel):\n";
        print OUTFILE "\tdef special_restraints(self, aln):\n";
        print OUTFILE "\t\trsr = self.restraints\n";
        print OUTFILE "a = automodel(env,\n";
        print OUTFILE "\talnfile  = '1tmpalign.ali',\n";
        print OUTFILE "\tknowns   = '1tmp',\n";
        print OUTFILE "\tsequence = '1aaa')\n";
        print OUTFILE "a.starting_model= 1\n";
        print OUTFILE "a.ending_model  = 1\n";
        print OUTFILE
"a.library_schedule = autosched.slow\na.max_var_iterations = 300\na.md_level = refine.slow\n";
        print OUTFILE "a.make()\n";
        close(OUTFILE);
        my $dir = getcwd;
        chdir($pdbcode);

        # Run modeller
        # my $cmd = "$MODELLER_PATH/$MODELLER_EXEC 1tmprelax.py ";
        my $modeller = catfile( $MODELLER_PATH, $MODELLER_EXEC );
        my $cmd = "$modeller 1tmprelax.py ";
        system $cmd;

        #Post-process modeller output
        for ( my $aa = 1 ; $aa < 2 ; $aa++ ) {
            my $fname = "1aaa.B9999" . sprintf( "%04d", $aa ) . ".pdb";
            move( "$fname", "Model.$ba.pdb" );
        }
        unlink glob "1aaa*";
        unlink glob "1tmp*";
        chdir($dir);

        print "Model $ba complete\n";
    }

}

=head1 AUTHORS

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>. 

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RunModeller

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

1;    # End of RunModeller
