#!perl
use warnings;
use strict;
use Data::Dumper;
use Cwd qw(cwd);
# 
# It runs  smotiftf pre-requisites
#
#    Pre-requisites
#    1. Get FASTA sequence. 
#    2. Run Psipred (- get .horiz and .ss2 files). 
#    3. Run HHblits  and get hhr file 
#    4. Run psi-blast and delta-blast 

#
#use lib "/home/cmadrid/test/lib/perl5/site_perl/5.8.8/";
#use lib "/home/user/MyPerlLib/share/perl5/";
use SmotifTF;

use SmotifTF::Psipred;
use SmotifTF::HHblits;
use SmotifTF::Psiblast;
 
use constant SMOTIFS_NUMBER_LOWER_LIMIT => 2;
use constant SMOTIFS_NUMBER_UPPER_LIMIT => 14;

use File::Spec::Functions qw(catfile catdir);
use Getopt::Long qw(GetOptions);
use Pod::Usage;
use Config::Simple;
use Carp;


my $config_file = $ENV{'SMOTIFTF_CONFIG_FILE'};
croak "Environmental variable SMOTIFTF_CONFIG_FILE should be set"
    unless $config_file;

my $cfg           = new Config::Simple($config_file);
my $localrun      = $cfg->param( -block => 'localrun' );
my $MAX_PROCESSES = $localrun->{'max_proc'};

my $dssp      = $cfg->param( -block => 'dssp' );
my $DSSP_PATH = $dssp->{'path'};
my $DSSP_EXEC = $dssp->{'exec'};

my $pdb      = $cfg->param( -block => 'pdb' );
my $PDB_DIR       = $pdb->{'uncompressed'};
my $PDB_OBSOLETES = $pdb->{'obsoletes'};
my $USER_SPECIFIC_PDB_PATH = $pdb->{'user_specific_pdb_path'};

my $hhsuite          = $cfg->param( -block => 'hhsuite' );
my $NR_HHM_DB        = $hhsuite->{'nr_hhm_db'};
my $PDB_HHM_DB       = $hhsuite->{'pdb_hhm_db'};

my $psiblast      = $cfg->param( -block => 'psiblast' );
my $PDBAA_DB      = $psiblast->{'pdbaa_db'};

my $sequence_file;
my $step = 0;
my $dir;
my $verbose;

my $man  = 0;
my $help = 0;

# smotiftf_prereq.pl -s 4wyq.fasta -d ./
my $result = GetOptions(
    "sequence_file=s" => \$sequence_file,  #  string
    "dir=s"           => \$dir,            # string
    "step=s"          => \$step,           # string
    "verbose"         => \$verbose,
    'help|?'          => \$help,
    man               => \$man
);

die "Failed to parse command line options\n" unless $result;

pod2usage( -exitval => 0, -verbose => 2 ) if $man;
pod2usage(1) if $help;
pod2usage(1) unless $sequence_file;

my $dispatch_for = {
    1       => \&run_psipred,
    2       => \&run_hhblits,
    3       => \&run_hhsearch,
    4       => \&run_psiblast,
    5       => \&run_deltablast,
    6       => \&reformat_psiblast_deltablast_combined_output,
    7       => \&run_analyze_psipred,
    8       => \&generate_dynamic_database,
    all     => \&execute_all,
    DEFAULT => sub { print "Unknown step.\n"; }
};

my $cwd = cwd();

my $func = $dispatch_for->{$step} || $dispatch_for->{DEFAULT};
$func->();

exit;

sub run_psipred {
    
    print "Step 1: running Psipred ...\n\n";
    eval {
        SmotifTF::Psipred::run( sequence => $sequence_file, directory => $dir );
    };
    if ($@) {
        print "Error: at run_psipred $@";
    }
    chdir $cwd;
}

sub run_hhblits {
    print "Step 2: Running hhblits ...\n";
    
    # check_step2( $pdb, $smotifs );
    eval {
        my $file_name = $sequence_file;
        $file_name =~ s/\.fasta//; 
        my $oa3m = $file_name.".a3m";  # 4wyq.a3m
        my $ohhm = $file_name.".hhm";  # 4wyq.hhm
       
         SmotifTF::HHblits::run_hhblits(
                sequence_fasta => $sequence_file,
                directory => $dir,
                database  => $NR_HHM_DB,
                oa3m      => $oa3m,
                ohhm      => $ohhm,
        );
=for
Writing HMM to 4wyq.hhm
Writing A3M alignment to 4wyq.a3m
=cut     
    };
    if ($@) {
        print "Error: at run_hhblits $@";
    }
    chdir $cwd;
}

sub run_hhsearch {
    print "Step 3: Running hhsearch ...\n";
    
    # check_step2( $pdb, $smotifs );
    eval {
        my $file_name = $sequence_file;
        $file_name =~ s/\.fasta//; 
        my $hhm = $file_name.".hhm";  # 4wyq.hhm
        my $hhr = $file_name.".hhr";  # 4wyq.hhr
        
        SmotifTF::HHblits::run_search(
                sequence_hhm => $hhm,
                directory => $dir,
                database  => $PDB_HHM_DB,
                ohhr      => $hhr,
        );  
    };
    if ($@) {
        print "Error: at run_hhsearch $@";
    }
    chdir $cwd;

}

sub run_psiblast {
    print "Step 4: Running psiblast ...\n";
    # check_step2( $pdb, $smotifs );

    eval {
        my $psiblast_out = 'outfile.txt';
        SmotifTF::Psiblast::run_psiblast(
            query          => $sequence_file,
            directory      => $dir, 
            database       => $PDBAA_DB,
            out            => $psiblast_out,
            evalue         => 100,
            num_iterations => 2
        );

    };
    if ($@) {
        print "Error: at run_psiblast $@";
    }
    chdir $cwd;
}

sub run_deltablast {
    print "Step 5: Running deltablast ...\n";
    
   # check_step2( $pdb, $smotifs );
    eval {
        my $deltablast_out = 'deltablast_outfile.txt';
        SmotifTF::Psiblast::run_deltablast(
            query          => $sequence_file,
            directory      => $dir, 
            database       => $PDBAA_DB,
            out            => $deltablast_out,
            evalue         => 100,
        );
    };
    if ($@) {
        print "Error: at run_deltablast $@";
    }
    chdir $cwd;
}

#
# hhr and psiblast, delatblast combined (reformatted) output
# columns
# 1 = pdb hit (sequence hit)
# 2 = chain
# 3 = evalue
# 4 = method 
#
# 2grk    A   2.0 DEL
# 2pmz    F   2.2 DEL
# 4ak4    B   4.4 HHS
# 4hqe    A   4.9 DEL
# 3sc0    A   5.9 HHS
# 1cq3    A   6.9 DEL
# 3som    A   8.4 HHS
# 2hwn    E   16  HHS
# 1fyh    A   16  HHS
# 1ytr    A   18  HHS
#
sub reformat_psiblast_deltablast_combined_output {
    
    print "Step 6: Reformat combined output...\n";
     
   
    my $file_name = $sequence_file;
    $file_name =~ s/\.fasta//; 
    
    # check_step2( $pdb, $smotifs );
    my $hhr_out        = $file_name.".hhr";  # 4wyq.hhr
    my $psiblast_out   = 'outfile.txt';
    my $deltablast_out = 'deltablast_outfile.txt';
    eval {
        my $file    = $sequence_file;
        my @seqlist = ();
        my $numhits = 0;
        my $cc1 = "PSI";
        my $cc2 = "DEL";
        my $cc3 = "HHS";
        ($numhits, @seqlist) = SmotifTF::HHblits::format_hhr_file($dir, $hhr_out, $file_name, $numhits, $cc3, @seqlist);
        ($numhits, @seqlist) = SmotifTF::Psiblast::format_blast_file($dir, $psiblast_out, $file_name, $numhits, $cc2, @seqlist);
        ($numhits, @seqlist) = SmotifTF::Psiblast::format_blast_file($dir, $deltablast_out, $file_name, $numhits, $cc2, @seqlist);
        
        @seqlist = sort {$a->[2] <=> $b->[2]} @seqlist;

        chdir $dir;
        # saving the smotif definfition for all sequence hits to *seqhits.evalue file
        my $file3 = "$file_name.seqhits.evalue";
        open(OUTFILE,">$file3");
        for (my $aa=0; $aa<scalar(@seqlist); $aa++) {
            print OUTFILE "$seqlist[$aa][0]\t$seqlist[$aa][1]\t$seqlist[$aa][2]\t$seqlist[$aa][3]\n";
        }
        close (OUTFILE);
    };
    if ($@) {
        print "Error: at run_deltablast $@";
    }
    chdir $cwd;
}

sub run_analyze_psipred {
    print "Step 7: Analyze psipred ...\n";
    
    my $file_name = $sequence_file;
    $file_name =~ s/\.fasta//; 
    
    # check_step2( $pdb, $smotifs );
    eval {
        my ($seq, $number_of_motifs) = SmotifTF::Psipred::analyze_psipred (
                pdb       => $file_name,
                directory => $dir,
        );
        # Proteins having more than 14 smotifs can not be processed
        # (time consuming)
        if ($number_of_motifs > SMOTIFS_NUMBER_UPPER_LIMIT) { 
            croak "$sequence_file contains more than the maximum allowed number of Smotifs";
        }
        if ($number_of_motifs < SMOTIFS_NUMBER_LOWER_LIMIT) {
            croak "$sequence_file contains less than the minimum allowed number of Smotifs";
        }
    };
    if ($@) {
        print "Error: at analyze_psipred  $@";
    }
    chdir $cwd;
}

# my $outputlogfile = $pdb_code . "_" . $chain . ".extract_loops.log";

# ##Run Joe's script to get Smotif definitions

#=head2  get_smotif_definition
# gettting the smotif definfition for all sequence hits
#  ./4wyq.seqhits.evalue
#   [cmadrid@manaslu test_SmotifTF]$ cat ./4wyq.seqhits.evalue
# 2grk	A	2.0	DEL
# 2pmz	F	2.2	DEL
# 4ak4	B	4.4	HHS
# 4hqe	A	4.9	DEL
# 3sc0	A	5.9	HHS
# 1cq3	A	6.9	DEL
# 3som	A	8.4	HHS
# 2hwn	E	16	HHS
# 1fyh	A	16	HHS
#
#
# $pdb_code,         $chain,            $smotiffields[2],
# 172                 $smotiffields[3],  $smotiffields[13], $smotiffields[11],
# 173                 $smotiffields[12], $smotiffields[7],  $smotiffields[8],
# 174                 $smotiffields[9],  $geoms[0],         $geoms[1],
# 175                 $geoms[2],         $geoms[3]
#
#
#ps is an array of lines. Eahc lines conatins the followinf values.
#2pmz	pdb_code,
#F	chain,
#HH	smotif_type
#16	smotif residue start
#26	loop length
#7	ss1 length
#7	ss2 length
#VAKKLLTDVIRSGGSSNLLQRTYDYLNSVEKCDAESAQKV	seq 
#HHHHHHHCCCCCCCCCCCCCCCCCCCCCCCCCCHHHHHHH	ss
#aaaaaaaaaaaaexebaaaaaaaaaaaaaxabbaaaaaaa	ramachandran
#13.507326	 
#145.200039	
#160.665006	
#226.951454',
#
#
#
sub generate_dynamic_database {
    print "Step 8: Generate Dynamic databases ...\n";
    
    my $file_name = $sequence_file;
    $file_name =~ s/\.fasta//; 
    
    # check_step2( $pdb, $smotifs );
    eval {
        # chdir $dir;
        #
        # get get_smotif_definition for the :
        # hhr,  psiblast, deltablast combined (reformatted) hits
        #
        
        # my @smotif = get_smotif_definition("./4wyq.seqhits.evalue");
        my $dd_file = $file_name.".seqhits.evalue"; 
        my $dd_path = catfile( $dir, $dd_file); 
        print "dd_file = $dd_path\n";
        my @smotif  = get_smotif_definition( $dd_path );
        # print "Smotif\n";
        # print Dumper( \@smotif );

        # we need pdb chain and evalue for the
        # hhr,  psiblast, deltablast combined (reformatted) hits
        my %newhash;
        # open(INFILE2,"$pdb/$pdb.seqhits.evalue"); # previous step
        # my $file = "./$pdb_code.seqhits.evalue";
        
        my $file = catfile( $dir, "$file_name.seqhits.evalue" );   # inout file
        # my $file = "./$file_name.seqhits.evalue";   # inout file
        open(INFILE2, $file ) or die "Cannot open $file $!"; # previous step
            while (my $line=<INFILE2>) {
            chomp $line;
            my @lin = split( /\s+/, $line);
            my $pdb   = $lin[0];
                my $chain = $lin[1];
                my $evalue= $lin[2];
            if ($pdb ne $file_name) {
                $newhash{$pdb.$chain} = $evalue;
            }
        }

        my $dd = 0;
        # open(OUTFILE5,">./dd_info_evalue.out");
        open(OUTFILE5,">$dir/dd_info_evalue.out");

            # for the hit from hhr,  psiblast, deltablast 
            # addd the evalue to the smotif info
            # getting form vilas's array pdb_id and chain's hit 
            my @smotlist = ();
            foreach my $hash (@smotif) {
                my $pdb_code = $hash->{'pdb_code'}; 
                my $chain    = $hash->{'chain'};
                $hash->{ 'evalue' } = $newhash{$pdb_code.$chain};
                push (@smotlist, $hash );
            }
            # then save it	
            my $num_mots = 0;
            #print "Start smotlist";
            #print Dumper(\@smotlist);
            #print "End smotlist";
            
            foreach my $href (@smotlist) {
                my $motifname = $dd + 400000;  # dd -dynamucic databstabese entry countet # nid
                $num_mots++;
                $dd++;
                
                my $pdb_code             = $href->{'pdb_code'}; 
                my $chain                = $href->{'chain'};     
                my $smotif_type          = $href->{'smotif_type'};  
                my $smotif_residue_start = $href->{'smotif_residue_start'};
                my $loop_length          = $href->{'loop_length'};
                my $ss1_length           = $href->{'ss1_length'};
                my $ss2_length           = $href->{'ss2_length'};
                my $sequence             = $href->{'sequence'}; 
                my $secondary_structure  = $href->{'secondary_structure'};
                my $ramachandran         = $href->{'ramachandran'}; 
                # my $num1  = $href->{'num1'};
                # my $num2  = $href->{'num2'};
                # my $num3  = $href->{'num3'};
                # my $num4  = $href->{'num4'};
                my $evalue= $href->{'evalue'};

                # dynamic database file
                print OUTFILE5 "$motifname\t$pdb_code\t$chain\t$smotif_type\t$smotif_residue_start\t$loop_length\t$ss1_length\t$ss2_length\t$sequence\t$secondary_structure\t$ramachandran\t$evalue\n";
            }
            close OUTFILE5;
            print "\nDone: Generating Dynamic databases\n";

    };
    if ($@) {
        print "Error: Generate Dynamic databases  $@";
    }
    chdir $cwd;
}

sub execute_all {
    run_psipred();
    run_hhblits();
    run_hhsearch();
    run_psiblast();
    run_deltablast();
    reformat_psiblast_deltablast_combined_output();
    run_analyze_psipred();
    generate_dynamic_database();
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
        my $file = $pdb . "_" . $smot . "_motifs_best.csv";

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

sub get_smotif_definition {
    use Try::Tiny;
 
        use SmotifTF::GetSMotifsfromPDB qw(missing_residues extract_loops);

        # Directory that holds the pdb files to be parsed

        $SmotifTF::GetSMotifsfromPDB::PDB_DIR       = $PDB_DIR;
        $SmotifTF::GetSMotifsfromPDB::PDB_OBSOLETES = $PDB_OBSOLETES;
		$SmotifTF::GetSMotifsfromPDB::USER_SPECIFIC_PDB_PATH = $USER_SPECIFIC_PDB_PATH;
        
        $SmotifTF::PDB::PDBfileParser::PDB_DIR       = $PDB_DIR;
        $SmotifTF::PDB::PDBfileParser::PDB_OBSOLETES = $PDB_OBSOLETES;
		$SmotifTF::PDB::PDBfileParser::USER_SPECIFIC_PDB_PATH = $USER_SPECIFIC_PDB_PATH;

        my ($full_path_name_file) = @_;

     die "full_path_name_file is required"
      unless $full_path_name_file;

    die "full_path_name_file does not exists"
      unless -e $full_path_name_file;

    my @smotif_definition;

    open my $list, "<", $full_path_name_file or die $!;
    while ( my $structline = <$list> ) {
        try {

            # structure line format
            # 1e9g      B       2.1     HHS
            chomp $structline;
            print "\nstructline = $structline\n";
            my @slin  = split( /\s+/, $structline );
            my $pdb   = $slin[0];
            my $chain = $slin[1];

         # get the smotifs
         # pdb_id, $uploadpdbfull = "pdb".$uploadpdb.$uploadchain.".ent", chain,
         # extracting smotif definition of pdb hits
            my @loops = SmotifTF::GetSMotifsfromPDB::extract_loops( $pdb, $chain );
            # print "THIS IS LOOPS\n";
            # print Dumper( \@loops );

            foreach my $line (@loops) {
                my @tmp = split( /\s+/, $line );
                
                next unless @tmp == 14;
                # print Dumper(\@tmp);
                my %hash = (
                    pdb_code             => $tmp[0],
                    chain                => $tmp[1],
                    smotif_type          => $tmp[2],
                    smotif_residue_start => $tmp[3],
                    loop_length          => $tmp[4],
                    ss1_length           => $tmp[5],
                    ss2_length           => $tmp[6],
                    sequence             => $tmp[7],
                    secondary_structure  => $tmp[8],
                    ramachandran         => $tmp[9],
                    num1                 => $tmp[10],
                    num2                 => $tmp[11],
                    num3                 => $tmp[12],
                    num4                 => $tmp[13],
                );

                # print "esta mielda es hash\n";
                # print Dumper(\%hash);
                push @smotif_definition, \%hash;
            }
        }
        catch {
            print  "Error at get_smotif_definition: $_ processing next file";
            next;
        };
    }    #end STRUCT loop
    close $list;

    return @smotif_definition;
}

=head1 NAME

SmotifTF Template-free Modeling Method - The pre-requisites

=head1 SYNOPSIS

SmotifTF carries out template-free structure prediction using a dynamic library 
of supersecondary structure fragments obtained from a set of remotely related 
PDB structures. 

This perl script runs all the pre-requisites (HHblits/HHsearch, Psi-Blast, 
Delta-Blast and Psipred) required for modeling. The input is the query
protein sequence in fasta format and the outputs are: 

1. A dynamic library of supersecondary structure motifs, tailor-made for the 
   query protein (obtained using HHblits/HHsearch, Psi-Blast and Delta-Blast). 

2. Definitions for putative Smotifs in the query protein (obtained from Psipred). 

Once the pre-requisites are completed, modeling can be carried out using the 
script smotiftf.pl (use "perldoc smotiftf.pl" for instructions). 

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


=head1 PRE-REQUISITES STEPS


      -------------------------------------------------------
     | Run Pre-requisites:                                   |
     | Psipred, HHblits+HHsearch, Psiblast, Delta-blast      |
     |                                                       |
     | Single-core job                                       |
     | Usage:                                                |
     |   perl smotiftf_prereq.pl --sequence_file=1zzz.fasta  |
     |         --dir=1zzz --step=all                         |
      -------------------------------------------------------


=head1 HOW TO RUN THE PRE-REQUISITES


1. If installed locally, provide the correct path name to the 
   SmotifTF perl library in this perl script (line 14).

2. Create a subdirectory with a dummy pdb file name (eg: 1abc or 1zzz). 

3. Put the query fasta file (1zzz.fasta) in this directory.

4. Run the pre-requisites step first. This runs Psipred, HHblits+HHsearch,
   Psiblast and Delta-blast. It will then generate the dynamic database of
   Smotifs and the list of putative Smotifs in the query protein.
   For more information about the pre-requisites use: 
   perl smotiftf_prereq.pl -help

   Usage: perl smotiftf_prereq.pl --sequence_file=1zzz.fasta --dir=1zzz --step=all

5. Next, run smotiftf.pl according to the instructions given there. For more 
   information use: perl smotiftf.pl -help

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

1,2,3,4,5,6,7,8 or all (to run all steps consecutively)

=item B<--sequence_file>
 
Give the name of the fasta file. 

=item B<--dir>

Give 4-letter dummy pdb_code or any other directory where the fasta file is present. 

=back

=head1 DESCRIPTION

B<SmotifTF> will carry out template-free structure prediction of a 
protein from its sequence to model its complete structure using the 
Smotif library.

=cut
