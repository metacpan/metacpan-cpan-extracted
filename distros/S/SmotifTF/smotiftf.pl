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

# use lib "/home/user/MyPerlLib/share/perl5/SmotifTF-version";
use SmotifTF;

use SmotifTF::CompareSmotifs qw( test_motif );
use SmotifTF::RankSmotifs qw( rank_all_smotifs );
use SmotifTF::EnumerateSmotifCombinations
  qw( enumerate pre_gen_list prepare_for_enumeration );
use SmotifTF::RankEnumeratedStructures qw( rank_structures pre_rank_structures );
use SmotifTF::RunModeller qw( get_model );

my $config_file = $ENV{'SMOTIFTF_CONFIG_FILE'};
croak "Environmental variable SMOTIFTF_CONFIG_FILE should be set"
  unless $config_file;

my $cfg           = new Config::Simple($config_file);
my $localrun      = $cfg->param( -block => 'localrun' );
my $MAX_PROCESSES = $localrun->{'max_proc'};

my $pdb;
my $step          = 0;
my $havestructure = 0;
my $verbose;

my $man  = 0;
my $help = 0;

my $result = GetOptions(
    "pdb_code=s"      => \$pdb,              #  string
    "step=s"          => \$step,             # string
    "verbose"         => \$verbose,
    'help|?'          => \$help,
    man               => \$man
);

die "Failed to parse command line options\n" unless $result;

pod2usage( -exitval => 0, -verbose => 2 ) if $man;
pod2usage(1) if $help;
pod2usage(1) unless $pdb;

my $dispatch_for = {
    1       => \&case_1,
    2       => \&case_2,
    3       => \&case_3,
    4       => \&case_4,
    5       => \&case_5,
    all     => \&execute_all,
    DEFAULT => sub { print "Unknown step.\n"; }
};

my $func = $dispatch_for->{$step} || $dispatch_for->{DEFAULT};
$func->();

exit;

sub case_1 {
    print
      "Step 1: Comparing Smotifs (this step may take a while)...\n\n";

    my $smfile = catfile ($pdb, "$pdb.out");

    unless ( -e $smfile ) {
        die
"Error: Smotif definiton file from Psipred is required. Run Psipred first\n";
    }

    eval {
        my $smotifs = SmotifTF::Psipred::count_pdb_smotifs($pdb);

        my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

      SMOTIFS:
        for ( my $i = 1 ; $i <= $smotifs ; $i++ ) {
            my $pid = $pm->start() and next SMOTIFS;
            my $motif_number = $i;

            print "Submiting motif number $motif_number\n";
            SmotifTF::CompareSmotifs::test_motif( 
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

sub case_2 {
    print
"Step 2: Ranking Smotifs ......\n";

    my $smfile = catfile( $pdb, "$pdb.out" );
    unless ( -e $smfile ) {
        die
"Error: Smotif definiton file from Psipred is required. Run Psipred first\n";
    }

    eval {
        my $smotifs = SmotifTF::Psipred::count_pdb_smotifs($pdb);
 
        check_step2( $pdb, $smotifs );

        print "Submiting for Smotif ranking\n";
        SmotifTF::RankSmotifs::rank_all_smotifs( $pdb );

    };
    if ($@) {
        print "Error: At ClusterRankSmotifs $@";
    }
}

sub case_3 {
    print
"Step 3: Enumerating all combinations of Smotifs (this step may take a while)...\n\n";

    my $smfile = catfile( "$pdb", "$pdb.out" );
    unless ( -e $smfile ) {
        die
"Error: Smotif definiton file from Psipred is required. Run Psipred first\n";
    }

    eval {

        # Get number of Smotifs
        my $smotifs = SmotifTF::Psipred::count_pdb_smotifs($pdb);

        check_step3( $pdb, $smotifs );

        # Prepare files needed for enumeration
        print "Preparing for enumeration ...\n\n";
        # SmotifTF::EnumerateSmotifCombinations::prepare_for_enumeration( $pdb, $smotifs );
        SmotifTF::EnumerateSmotifCombinations::prepare_for_enumeration( $pdb );

        # Check for input file for enumeration
        my $bestfile = catfile( "$pdb", "$pdb" . "_motifs_best.csv" );
        die "Error: $bestfile is required. Run steps 1-2 first"
          unless -e $bestfile;

        # Get number of jobs
        my @joblist =
          SmotifTF::EnumerateSmotifCombinations::pre_gen_list( $pdb, $smotifs );

        my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

      JOBS:
        for ( my $i = 0 ; $i < scalar(@joblist) ; $i++ ) {
            my $pid = $pm->start() and next JOBS;
            my $job_number = $joblist[$i];
            print "\tSubmiting job number $job_number\n";
            
            SmotifTF::EnumerateSmotifCombinations::enumerate( 
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

sub case_4 {
    print "Step 4: Ranking enumerated structures ...\n\n";

    my $smfile = catfile( "$pdb", "$pdb.out" );
    unless ( -e $smfile ) {
        die
"Error: Smotif definiton file from Psipred is required. Run Psipred first\n";
    }

    eval {
        my $smotifs = SmotifTF::Psipred::count_pdb_smotifs($pdb);

        check_step4($pdb);
        
        my ( $sterlimit, @st ) =
          SmotifTF::RankEnumeratedStructures::pre_rank_structures($smotifs);
          SmotifTF::RankEnumeratedStructures::rank_structures( $pdb, $sterlimit, @st );
    };
    if ($@) {
        print "Error: At  RankEnumeratedStructures $@";
    }
}

sub case_5 {
    print "Step 5: Running Modeller ...\n\n";

    my $rankfile = catfile( "$pdb", "$pdb" . '_ranked_refined.csv' );
    unless ( -e $rankfile ) {
        die "Error: Ranking file from step 4 $rankfile is required. 
        Run steps 1-4 first\n"
    }

    eval { 
        SmotifTF::RunModeller::get_model($pdb); 
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
}

sub check_step2 {

    use File::Find::Rule;

    my ( $pdb, $smotifs ) = @_;

    for ( my $i = 1 ; $i <= $smotifs ; $i++ ) {
        my $motif_number = $i;
        my $smot         = sprintf( "%02d", $motif_number );    #pad with zeros
        my $rule         = File::Find::Rule->new;
        $rule->file;
        
        my $file = "dd_shiftcands" . $pdb . "_" . $smot;
        $rule->name(qr/$file/);
        my @file_full_path = $rule->in($pdb);

        if ( scalar(@file_full_path) == 0 ) {
            die "Output from step 1 is required for $pdb Smotif $i. 
            Run steps 1 first\n";
        }
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

        # 1aab_01_motifs_best.csv
        # my $file = $pdb . "_" . $smot . "_motifs_best.csv";
        my $file = $pdb . "_motifs_best.csv";

        print "Looking for $pdb\/$file\n";
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

    my ($pdb) = @_;

    my $rule = File::Find::Rule->new;
    $rule->file;
    my $file = "-all_enum_$pdb.csv";
    
    $rule->name(qr/$file/);
    my @file_full_path = $rule->in($pdb);
    if ( scalar(@file_full_path) == 0 ) {
        die "Enumeration output from step 3 is required for step 4. 
        Run steps 1-3 first for $pdb\n";
    }
}

=head1 NAME

SmotifTF Template-free Modeling Method

=head1 SYNOPSIS

SmotifTF carries out template-free structure prediction using a dynamic library 
of supersecondary structure fragments obtained from a set of remotely related 
PDB structures.

=head1 PRE-REQUISITES 

The Smotif-based modeling algorithm requires the query protein sequence as input. 

Software / data:

1. Psipred (http://bioinf.cs.ucl.ac.uk/psipred/)

2. HHSuite (ftp://toolkit.genzentrum.lmu.de/pub/HH-suite/)

3. Psiblast and Delta-blast (http://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download)

4. Modeller (version 9.14 https://salilab.org/modeller/)

5. DSSP (http://swift.cmbi.ru.nl/gv/dssp/)

6. Local PDB directory (central or user-designated from http://www.rcsb.org). Many PDB structures
   are incomplete with missing residues. The SmotifTF algorithm performs best when the PDB 
   structures are complete. Hence, we use Modeller (https://salilab.org/modeller/) to model the 
   missing residues in the PDB to obtain complete structures. The algorithm can work with 
   incomplete PDB structures but the performance may not be as expected. The SMotifTF software 
   can handle gzipped (.gz) or unzipped (.ent) PDB structure files. 

   The software for remodeling the missing residues can be obtained from our website at: 
   http://fiserlab.org/remodel_pdb.tar.gz
   This can be used to remodel missing residues in the entire PDB and these remodeled
   structures can be used in the SmotifTF package. The SmotifTF package can handle both
   regular and remodeled PDB database.


Download and install the above mentioned software / data according to their instructions. 

Note: Psipred may require legacy blast and Psiblast and Delta-blast are part of the Blast+ package. 
      .ncbirc file may be required in the home directory for Psipred. 
    
Databases required: 

1. PDBAA blast database is required (ftp://ftp.ncbi.nlm.nih.gov/blast/db/). 

2. HHsuite databases NR20 and PDB70 are required (ftp://toolkit.genzentrum.lmu.de/pub/HH-suite/databases/hhsuite_dbs/)

=head1 SMOTIFTF DOWNLOAD AND INSTALLATION

Download SmotifTF package from CPAN: 

http://search.cpan.org/dist/SmotifTF/

Installation of the software (also available in the README file):

 tar -zxvf SmotifTF-version.tar.gz

 cd SmotifTF-version/

 perl Makefile.PL PREFIX=/home/user/MyPerlLib/

 make

 make test

 make install

=head1 SETUP CONFIGURATION FILE

The configuration file, smotiftf_config.ini has all the information
regarding the required library files and other pre-requisite software. 

Set all the paths and executables in this file correctly.

Set environment varible in .bashrc file:

export SMOTIFTF_CONFIG_FILE=/home/user/MyPerlLib/share/perl5/SmotifTF-version/smotiftf_config.ini

=head1 MODELING ALGORITHM STEPS

       ----------------------------------------------------
      |First run the Pre-requisites:                       |
      |   Psipred, HHblits+HHsearch, Psiblast,             |
      |         Delta-blast                                |
      |                                                    |
      |   Single-core job                                  |
      |   Usage: perl smotiftf_prereq.pl --step=all        |
      |    --sequence_file=1zzz.fasta --dir=1zzz           |
       ----------------------------------------------------

       ----------------------------------------------------
      |   Step 1:                                          |
      |         Compare Smotifs                            |
      |                                                    |
      |   Multi-core / cluster job                         |
      |   Usage: perl smotiftf.pl --step=1 --pdb=1zzz      |
       ----------------------------------------------------

       ----------------------------------------------------
      |   Step 2:                                          | 
      |         Rank Smotifs                               |
      |                                                    |
      |   Multi-core / cluster job                         |
      |   Usage: perl smotiftf.pl --step=2 --pdb=1zzz      |
       ----------------------------------------------------

       ----------------------------------------------------
      |   Step 3:                                          |
      |         Enumerate all possible combinations of     | 
      |         Smotifs (about a million models)           |
      |                                                    |
      |   Multi-core / cluster job                         |
      |   Usage: perl smotiftf.pl --step=3 --pdb=1zzz      |
       ----------------------------------------------------

       ----------------------------------------------------
      |   Step 4:                                          |   
      |         Rank enumerated structures using a         |
      |         composite energy function                  |
      |                                                    |
      |   Single-core job                                  |
      |   Usage: perl smotiftf.pl --step=4 --pdb=1zzz      |
       ----------------------------------------------------

       ----------------------------------------------------
      |   Step 5:                                          |   
      |         Run Modeller to generate top 5 complete    |  
      |         models                                     |
      |                                                    |
      |   Single-core job                                  |
      |   Usage: perl smotiftf.pl --step=5 --pdb=1zzz      |
       ----------------------------------------------------


=head1 HOW TO RUN THE MODELING ALGORITHM

1. If installed locally, provide the correct path name to the 
   SmotifTF perl library in this perl script (line 14).

2. Create a subdirectory with a dummy pdb file name (eg: 1abc or 1zzz). 

3. Put the query fasta file (1zzz.fasta) in this directory.

4. Run the pre-requisites first. This runs Psipred, HHblits+HHsearch,
   Psiblast and Delta-blast. Input is the query sequence in fasta format 
   and the outputs are (a) dynamic database of Smotifs and (b) the putative 
   Smotifs in the query protein. These are used in the subsequent modeling 
   steps. Follow the instructions given in smotiftf_prereq.pl. For more 
   information about the pre-requisites use: perl smotiftf_prereq.pl -help

   Usage: perl smotiftf_prereq.pl --step=all --sequence_file=1zzz.fasta --dir=1zzz

5. After the pre-requisites are completed, run steps 1 to 5 as given 
   above sequentially. Output from previous steps are often required 
   in subsequent steps. Wait for each step to be completed without 
   errors before going to the next step. For more information use: 
   perl smotiftf.pl -help

   Usage: perl smotiftf.pl --step=[1-5] --pdb=1zzz

6. To run steps 1-5 together use: 
   perl smotiftf.pl --step=all --pdb=1zzz

7. Use multiple-cores or clusters as available, for steps 1 & 3 above.  
   These are slow and require a lot of computational resources. 

Results: 

Top 5 models are stored in the subdirectory (1abc or 1zzz) as:
Model.1.pdb, Model.2.pdb, Model.3.pdb, Model.4.pdb & Model.5.pdb 

=head1 REFERENCE

Vallat BK, Fiser A.
Modularity of protein folds as a tool for template-free modeling of sequences
Manuscript under review. 

=head1 AUTHORS

Brinda Vallat, Carlos Madrid and Andras Fiser. 


=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<--step>

1,2,3,4,5 or all (to run all steps consecutively)

=item B<--pdb>

Give 4-letter dummy pdb_code directory, where all input/output are stored. 

=back

=head1 DESCRIPTION

B<SmotifTF> will carry out template-free structure prediction of a 
protein from its sequence to model its complete structure using the 
Smotif library.

=cut
