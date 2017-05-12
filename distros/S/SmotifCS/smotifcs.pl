#!perl

use warnings;
use strict;

use File::Spec::Functions qw(catfile);
use Getopt::Long qw(GetOptions);
use Pod::Usage;
use Config::Simple;
use Carp;
use Parallel::ForkManager;
use Config::Simple;

# use lib "$ENV{HOME}/MyLib/share/perl5/";
use SmotifCS;

use SmotifCS::GenerateShiftFiles qw( run_and_analyze_talos count_pdb_smotifs );
use SmotifCS::Compare_shifts_torsion qw( test_motif );
use SmotifCS::ClusterRankSmotifs qw( rank_smotifs );
use SmotifCS::EnumerateSmotifCombinations
  qw( enumerate pre_gen_list prepare_for_enumeration );
use SmotifCS::RankEnumeratedStructures qw( rank_structures pre_rank_structures );
use SmotifCS::RunModeller qw( get_model );

my $config_file = $ENV{'SMOTIFCS_CONFIG_FILE'};
croak "Environmental variable SMOTIFCS_CONFIG_FILE should be set"
  unless $config_file;

my $cfg           = new Config::Simple($config_file);
my $localrun      = $cfg->param( -block => 'localrun' );
my $MAX_PROCESSES = $localrun->{'max_proc'};

my $pdb;
my $chain         = 'A';
my $step          = 0;
my $havestructure = 0;
my $dir;
my $cs_filename;
my $verbose;

my $man  = 0;
my $help = 0;

my $result = GetOptions(
    "pdb_code=s"      => \$pdb,              #  string
    "chain=s"         => \$chain,            # string
    "havestructure=s" => \$havestructure,    # flag
    "dir=s"           => \$dir,              # string
    "cs_filename=s"   => \$cs_filename,      # string
    "step=s"          => \$step,             # string
    "verbose"         => \$verbose,
    'help|?'          => \$help,
    man               => \$man
);

die "Failed to parse command line options\n" unless $result;

pod2usage( -exitval => 0, -verbose => 2 ) if $man;
pod2usage(1) if $help;
pod2usage(1) unless $pdb;

if ( defined $havestructure ) {
    if ( !defined $pdb ) {
        my $message_text = "pdb code is required";
        pod2usage($message_text);
    }
    if ( !defined $chain ) {
        my $message_text = "chain is required";
        pod2usage($message_text);
    }
}

my $dispatch_for = {
    1       => \&case_1,
    2       => \&case_2,
    3       => \&case_3,
    4       => \&case_4,
    5       => \&case_5,
    6       => \&case_6,
    all     => \&execute_all,
    DEFAULT => sub { print "Unknown step.\n"; }
};

my $func = $dispatch_for->{$step} || $dispatch_for->{DEFAULT};
$func->();

exit;

sub case_1 {

    print
      "Step 1: Generating secondary structure information using TALOS+ ...\n\n";

    unless ( -d $pdb ) {
        die "Error: A dummy 4-letter pdb directory $pdb is required\n";
    }

    my $shiftfile = catfile( $pdb, 'pdb' . "$pdb" . "shifts.dat" );
    unless ( -e $shiftfile ) {
        die "Error: Chemical shift input file $shiftfile is required\n";
    }

    eval {
        print "Running TALOS\n";
        SmotifCS::GenerateShiftFiles::run_and_analyze_talos( $pdb, $chain );
    };
    if ($@) {
        print "Error: At GenerateShiftFiles $@";
    }
}

sub case_2 {
    print
      "Step 2: Comparing chemical shifts (this step may take a while)...\n\n";

    my $smfile = "$pdb/$pdb.out";

    unless ( -e $smfile ) {
        die
"Error: Smotif definiton file from step 1 is required. Run step 1 first\n";
    }

    my $predfile = catfile( $pdb, "pred$pdb.tab" );
    unless ( -e $predfile ) {
        die "Error: TALOS output from step 1 is required. Run step 1 first\n";
    }

    eval {
        my $smotifs = SmotifCS::GenerateShiftFiles::count_pdb_smotifs($pdb);


        check_step2( $pdb, $smotifs );

        my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

      SMOTIFS:
        for ( my $i = 1 ; $i <= $smotifs ; $i++ ) {
            my $pid = $pm->start() and next SMOTIFS;
            my $motif_number = $i;

            print "Submiting motif number $motif_number\n";
            SmotifCS::Compare_shifts_torsion::test_motif( 
                $pdb, 
                $havestructure,
                $motif_number 
            );

            $pm->finish;    # do the exit in the child process
        }
        $pm->wait_all_children;  # blocks until all forked processes have exited
    };
    if ($@) {
        print "Error: At Compare_shifts_torsion $@";
    }
}

sub case_3 {
    print
"Step 3: Clustering and Ranking Smotifs (this step may take a while)...\n\n";

    my $smfile = catfile( $pdb, "$pdb" . '.out' );
    unless ( -e $smfile ) {
        die
"Error: Smotif definiton file from step 1 is required. Run step 1 first\n";
    }

    eval {
        my $smotifs = SmotifCS::GenerateShiftFiles::count_pdb_smotifs($pdb);


        check_step3( $pdb, $smotifs );

        my $pm = Parallel::ForkManager->new($MAX_PROCESSES);
      SMOTIFS:
        for ( my $i = 1 ; $i <= $smotifs ; $i++ ) {
            my $pid = $pm->start() and next SMOTIFS;
            my $motif_number = $i;

            print "Submiting motif number $motif_number\n";
            $SmotifCS::ClusterRankSmotifs::VERBOSE = $verbose if $verbose;
            SmotifCS::ClusterRankSmotifs::rank_smotifs( $pdb, $motif_number );

            $pm->finish;    # do the exit in the child process
        }
        $pm->wait_all_children;  # blocks until all forked processes have exited
    };
    if ($@) {
        print "Error: At ClusterRankSmotifs $@";
    }
}

sub case_4 {
    print
"Step 4: Enumerating all combinations of Smotifs (this step may take a while)...\n\n";

    my $smfile = catfile( "$pdb", "$pdb" . '.out' );
    unless ( -e $smfile ) {
        die
"Error: Smotif definiton file from step 1 is required. Run step 1 first\n";
    }

    eval {

        # Get number of Smotifs
        my $smotifs = SmotifCS::GenerateShiftFiles::count_pdb_smotifs($pdb);


        check_step4( $pdb, $smotifs );

        # Prepare files needed for enumeration
        print "Preparing for enumeration ...\n\n";
        SmotifCS::EnumerateSmotifCombinations::prepare_for_enumeration( $pdb, $smotifs );

        # Check for input file for enumeration
        my $bestfile = catfile( "$pdb", "$pdb" . "_motifs_best.csv" );
        die "Error: $bestfile is required. Run steps 1-3 first"
          unless -e $bestfile;

        # Get number of job
        my @joblist =
          SmotifCS::EnumerateSmotifCombinations::pre_gen_list( $pdb, $smotifs );

        my $pm = Parallel::ForkManager->new($MAX_PROCESSES);
        $havestructure = 1;
      JOBS:
        for ( my $i = 0 ; $i < scalar(@joblist) ; $i++ ) {
            my $pid = $pm->start() and next JOBS;
            my $job_number = $joblist[$i];
            print "\tSubmiting job number $job_number\n";
            
            SmotifCS::EnumerateSmotifCombinations::enumerate( 
                $pdb, 
                $job_number,
                $havestructure 
            );

            $pm->finish;    # do the exit in the child process
        }
        $pm->wait_all_children;  # blocks until all forked processes have exited
    };
    if ($@) {
        print "Error: At EnumerateSmotifCombinations $@";
    }
}

sub case_5 {
    print "Step 5: Ranking enumerated structures ...\n\n";

    my $smfile = catfile( "$pdb", "$pdb" . '.out' );
    unless ( -e $smfile ) {
        die
"Error: Smotif definiton file from step 1 is required. Run step 1 first\n";
    }

    eval {
        my $smotifs = SmotifCS::GenerateShiftFiles::count_pdb_smotifs($pdb);
        check_step5($pdb);
        
        my ( $sterlimit, @st ) =
          SmotifCS::RankEnumeratedStructures::pre_rank_structures($smotifs);
          SmotifCS::RankEnumeratedStructures::rank_structures( $pdb, $sterlimit, @st );
    };
    if ($@) {
        print "Error: At  RankEnumeratedStructures $@";
    }
}

sub case_6 {
    print "Step 6: Running Modeller ...\n\n";

    my $rankfile = catfile( "$pdb", "$pdb" . '_ranked_refined.csv' );
    unless ( -e $rankfile ) {
        die "Error: Ranking file from step 5 $rankfile is required. 
        Run steps 1-5 first\n"
    }

    eval { 
        SmotifCS::RunModeller::get_model($pdb); 
    };
    if ($@) {
        print "Error: At  RunModeller $@";
    }
}

sub execute_all {
    case_1();
    case_2();
    case_3();
    case_4();
    case_5();
    case_6();
}

sub check_step2 {
    my ( $pdb, $smotifs ) = @_;

    for ( my $i = 1 ; $i <= $smotifs ; $i++ ) {
        my $motif_number = $i;
        my $csfile =
          catfile( $pdb, "pdb$pdb" . "_shifts$motif_number" . ".dat" );

        die
"CS output from step 1 is required for $pdb Smotif $i. Run step 1 first"
          unless -e $csfile;
    }
}

sub check_step3 {

    use File::Find::Rule;

    my ( $pdb, $smotifs ) = @_;

    for ( my $i = 1 ; $i <= $smotifs ; $i++ ) {
        my $motif_number = $i;
        my $smot         = sprintf( "%02d", $motif_number );    #pad with zeros
        my $rule         = File::Find::Rule->new;
        $rule->file;
        
        my $file = "shiftcands" . $pdb . "_" . $smot;
        $rule->name(qr/$file/);
        my @file_full_path = $rule->in($pdb);

        if ( scalar(@file_full_path) == 0 ) {
            die "Output from step 2 is required for $pdb Smotif $i. 
            Run steps 1-2 first\n";
        }
    }
}

sub check_step4 {

    use File::Find::Rule;

    my ( $pdb, $smotifs ) = @_;

    for ( my $i = 1 ; $i <= $smotifs ; $i++ ) {
        my $motif_number = $i;
        my $smot         = sprintf( "%02d", $motif_number );    #pad with zeros
        my $rule         = File::Find::Rule->new;
        $rule->file;

        # 1aab_01_motifs_best.csv
        my $file = $pdb . "_" . $smot . "_motifs_best.csv";

        print "Looking for $pdb\/$file\n";
        $rule->name(qr/$file/);
        my @file_full_path = $rule->in($pdb);

        if ( scalar(@file_full_path) == 0 ) {
            die "Output from step 3 is required for $pdb Smotif $i. 
            Run steps 1-3 first\n";
        }
    }
}

sub check_step5 {
    use File::Find::Rule;

    my ($pdb) = @_;

    my $rule = File::Find::Rule->new;
    $rule->file;
    my $file = "-all_enum_$pdb.csv";
    
    $rule->name(qr/$file/);
    my @file_full_path = $rule->in($pdb);
    if ( scalar(@file_full_path) == 0 ) {
        die "Enumeration output from step 4 is required for step 5. 
        Run steps 1-4 first for $pdb\n";
    }
}

=head1 NAME

SmotifCS Hybrid Modeling Method

=head1 SYNOPSIS

Please read this document completely for running the SmotifCS
software successfully on any local computer. 

Pre-requisites: 

The hybrid modeling algorithm requires a BMRB formatted chemical shift file as
input. Additionally, if the structure of the protein is known from any alternate
resource, then a PDB-formatted structure file is required. This pdb-file can be
present in a centralized local directory or a user-designated separate directory. 

Software / data:

1. MySQL   - To install the Smotif Database 

2. NMRPipe/TALOS - (http://spin.niddk.nih.gov/NMRPipe/)

3. Modeller (version 9.14 https://salilab.org/modeller/)

4. Phylip   (version 3.69 http://evolution.genetics.washington.edu/phylip.html)

5. Local PDB directory (central or user-designated) - updated (http://www.rcsb.org). 

Download and install the above mentioned software / data according to their instructions. 

SmotifCS Download and Installation: 

The following three components need to be downloaded and
installed to run SmotifCS: 

1. The software from CPAN (http://)

2. The Smotif library (http://fiserlab.org)

3. The chemical shift library (http://fiserlab.org)

Installation of the software (also available in the README file):

	tar -zxvf SmotifCS-0.01.tar.gz

	cd SmotifCS-0.01/

	perl Makefile.PL PREFIX=/home/user/SmotifCS-0.01

	make

	make test

	make install

Installation of the Smotif library using MYSQL:


Installation of the chemical shift library (flat files):


Set up the configuration file:

The configuration file, smotifcs_config.ini has all the information
regarding the required library files and other pre-requisite software. 

Set all the paths and executables in this file correctly.

Set environment varible in .bashrc file:

export SMOTIFCS_CONFIG_FILE=/home/user/SmotifCS-0.01/smotifcs_config.ini




	Modeling algorithm steps: 

	 ----------------------------------------------------
	|Step 1:				             |
	|	Run Talos+			             |
	|	Get SS, Phi/PSi, Smotif Information          |
	|	Single-core job		     	             |
	|	Usage: perl smotifcs.pl --step=1 --pdb=1zzz  |
	|	       --chain=A --havestructure=0	     |
	 ----------------------------------------------------

	 ----------------------------------------------------
        |Step 2:                                             |
        |       Compare experimental CS of Query SmotifS     |       
        |       to theoretical CS of library Smotifs         |
	|	Multi-core / cluster job		     |
	|       Usage: perl smotifcs.pl --step=2 --pdb=1zzz  |
        |              --chain=A --havestructure=0           |
         ----------------------------------------------------

 	 ----------------------------------------------------
        |Step 3:                                             |
        |       Cluster and rank chosen SmotifS     	     |
        |       				             |
        |       Multi-core / cluster job                     |  
	|       Usage: perl smotifcs.pl --step=3 --pdb=1zzz  |
        |              --chain=A --havestructure=0           |
         ----------------------------------------------------

	 ----------------------------------------------------
        |Step 4:                                             |
        |       Enumerate all possible combinations of       |
        |       Smotifs	(about a million models)	     |
        |       Multi-core / cluster job                     |  
	|       Usage: perl smotifcs.pl --step=4 --pdb=1zzz  |
        |              --chain=A --havestructure=0           |
         ----------------------------------------------------

	 ----------------------------------------------------
        |Step 5:                                             |
        |       Rank enumerated structures using a	     |
        |       composite energy function         	     |
        |       Single-core job                     	     |  
	|       Usage: perl smotifcs.pl --step=5 --pdb=1zzz  |
        |              --chain=A --havestructure=0           |
         ----------------------------------------------------

	 ----------------------------------------------------
        |Step 6:                                             |
        |       Run Modeller to generate top 5 complete      |
        |       models         				     |
        |       Single-core job                     	     |  
	|       Usage: perl smotifcs.pl --step=6 --pdb=1zzz  |
        |              --chain=A --havestructure=0           |
         ----------------------------------------------------


How to run the program:

1. Create a subdirectory with a dummy pdb file name (eg: 1abc or 1zzz). 

2. Put the chemical shift input file (in BMRB format) in this directory.
   Use the filename 1abc/pdb1abcshifts.dat or 1zzz/pdb1zzzshifts.dat for
   the BMRB formatted chemical shift input file. 

3. Optional: If structure is known, include a pdb format structure file
   in the same directory. 1abc/pdb1abc.ent or 1zzz/pdb1zzz.ent

4. Run steps 1 to 6 as given above sequentially. Output from previous
   steps are often required in subsequent steps. Wait for each step to
   be completed without errors before going to the next step. 

5. To run all steps together use: 
   perl smotifcs.pl --step=all --pdb=1zzz --chain=A --havestructure=0

6. Use multiple-cores or clusters as available, for steps 2, 3 & 4.  
   These are slow and require a lot of computational resources. 

7. If structure is known, use --havestructure=1.
   Else, use --havestructure=0 in all the steps. 

Results: 

Top 5 models are stored in the subdirectory (1abc or 1zzz) as:
Model.1.pdb, Model.2.pdb, Model.3.pdb, Model.4.pdb & Model.5.pdb	

Reference: 

Menon V, Vallat BK, Dybas JM, Fiser A.
Modeling proteins using a super-secondary structure library and NMR chemical
shift information.
Structure, 2013, 21(6):891-9.

Authors:

Vilas Menon, Brinda Vallat, Joe Dybas, Carlos Madrid and Andras Fiser. 


=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<--step>

1,2,3,4,5,6 or all

=item B<--pdb>

Give 4-letter dummy pdb_code

=item B<--chain>

Give 1-letter chain_id

=item B<--havestructure>

0 or 1 depending on whether a structure is known for the protein from
alternate sources. 

=back

=head1 DESCRIPTION

B<SmotifCS> will use the experimentally determined chemical shift information 
for a protein to model its complete structure using the Smotif library.

=cut
