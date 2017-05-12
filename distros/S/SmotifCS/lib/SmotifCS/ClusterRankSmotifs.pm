package SmotifCS::ClusterRankSmotifs;

use 5.10.1 ;
use strict;
use warnings;
use SmotifCS::GeometricalCalculations;
use SmotifCS::Protein;
use SmotifCS::GenerateShiftFiles;
use SmotifCS::PhylipParser;

use Data::Dumper;
use Carp;
use File::Copy;
use Cwd;
use File::Spec::Functions qw(catfile);

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = "0.1";

    # $AUTHOR  = "Vilas Menon(vilas\@fiserlab.org )";
    @ISA = qw(Exporter);
    
    #Name of the functions to export
    @EXPORT = qw(
	rank_smotifs
    );

    #Name of the functions to export on request
    @EXPORT_OK = qw(
	findranks_by_cs_clustered
	get_cluster_on_the_go
   	getseq
   	checkseqblosum
	read_clusters
	get_clusters
	read_joe_clusters
    );  
}

our $VERBOSE;

use constant DEBUG => 0;
our @EXPORT_OK;
use Config::Simple;
my $config_file = $ENV{'SMOTIFCS_CONFIG_FILE'};
croak "Environmental variable SMOTIFCS_CONFIG_FILE should be set" unless $config_file;
my $cfg    = new Config::Simple($config_file );

my $phylip  = $cfg->param(-block=>'phylip');
my $PHYLIP_PATH = $phylip->{'path'};
my $PHYLIP_EXEC = $phylip->{'exec'};

my $motifclusters = $cfg->param(-block=>'motifclusters');
my $MOTIFCLUSTERS_PATH = $motifclusters->{'path'};

=head1 NAME

ClusterRankSmotifs

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our $DEBUG = 0;

=head1 SYNOPSIS

Script to rank smotifs in the database by their loop signature and chemical shift difference
as compared to a query smotif. Two parallel clustering and ranking methods are used: 
(a) cluster on the go and rank based on population (b) Joe's clusters and rank using diversity. 

INPUT ARGUMENTS
1) $pdbcode : 4-letter name of the folder where the experimental chemical shift data is stored
2) $smotif : smotif number in the pdb

INPUT FILES
In the <pdbcode> folder:
1) shiftcands<pdbcode><motnum>_<looplength><smotif type>.csv : Files containing results of comparing the query smotifs
against the database. Each file (corresponding to each smotif) includes the number of residues compared, the chemical 
shift difference value, the RMSD (if structure is included), the loop length, the smotif NID, the secondary structure RMSD, 
secondary structure lengths, and loop structural signatures for the query and database motif and their overlap.

OUTPUT FILES
In the <pdbcode> folder:
1) <pdbcode>_motifs_best_XX.csv : File containing a list of smotif candidates for each query smotif in the unknown protein
2) <pdbcode>_motifs_rmsd_XX.csv : File containing rmsds of smotif candidates for each query smotif in the unknown protein. 
XX = Query Smotif number.

Usage:

    use ClusterRankSmotifs;

    ClusterRankSmotifs ($pdb,$smotif);

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES

	rank_smotifs
	findranks_by_cs_clustered
        get_cluster_on_the_go
	getseq
        checkseqblosum
        read_clusters
        get_clusters
        read_joe_clusters


=head2 rank_smotifs

	Subroutine to cluster and rank the smotifs from the library based on the 
	chemical difference and phi/psi signature match between the library Smotif
	and the query Smotif. 

=cut

sub rank_smotifs {
    use File::Spec::Functions qw(catfile);
	my ($pdbcode,$smotif) = @_;

	croak "4-letter pdbcode is required as input" unless $pdbcode;
	croak "Smotif number is required as input"    unless $smotif;

	my $threshold=2.0;  #RMSD threshold for clustering

	#Get the list of all smotif CS comparison files in the directory
	my $smot = sprintf("%02d", $smotif); #pad with zeros
    my $nam = "shiftcands".$pdbcode."_".$smot."_";
    
    my $nam2=`ls $pdbcode/$nam*csv`;
=for    
    # Added by CMA to replace my $nam2=`ls $pdbcode/$nam*csv`;
    # for something more portable 
    my $look_for= catfile( $pdbcode, "$nam*csv");
    # print "look_for= $look_for\n";
    my @found   = glob $look_for;
    
    die "rank_smotifs: no file like $nam*csv was found in $pdbcode"
        unless @found;
    # Let's assume that just ONE file like $pdbcode/$nam*csv was found.
    # $nam2  = 1aab/shiftcands1aab_01_8HH.csv
    my $nam2 = $found[0];
=cut
    print "nam2 = $nam2\n";
    # End added

	#Find the number of Smotifs in the given query protein
	# my $filename2 = "$pdbcode/$pdbcode.out";
	my $filename2 = catfile($pdbcode, "$pdbcode.out");
	die "rank_smotifs $filename2 does not exist" 
        unless -e $filename2;
    
    my $num_mots  = SmotifCS::GenerateShiftFiles::count_smotifs($filename2);

	# Get information about query smotif from the filename
	if ($nam2 =~ /$pdbcode\/shiftcands(\w+)\.csv/) {
        my $filename = $1; # 1aab_01_8HH
        my $count    = 0;
        my $looplen;	
		print "filename = $filename\n";
        # Get loop length from filename
		if ( $filename =~ /\w+\_(\d+)\_(\d+)../ ) {
            $count  = $1-1;
            $looplen= $2;
        }
        # Get the query sequence
        # print "getseq $filename $pdbcode\n";
		# 1aab_01_8HH 1aab
        my $seq = getseq( $filename, $pdbcode );
        die "rank_smotifs: getseq Could not get seq"
            unless $seq;
	    #print "seq = $seq\n"; # HKKKHPDASVNFSE	
        findranks_by_cs_clustered ($filename,$seq,$pdbcode,$looplen,$smot,$threshold,$num_mots);
   	} else { 
		croak "No CS comparison file for $pdbcode\t$smotif\n";
	}
}

=head2 findranks_by_cs_clustered

	Subroutine to cluster and rank the smotifs from the library based on the 
        chemical difference and phi/psi signature match between the library Smotif
        and the query Smotif.

=cut

sub findranks_by_cs_clustered {
    use File::Spec::Functions qw(catfile);	

	my($filename,$seq,$pdbcode,$looplen,$smot,$threshold,$num_mots)=@_;

    # print "at findranks_by_cs_clustered\n";

	croak "Sequence is required"          unless $seq;
	croak "4-letter pdb code is required" unless $pdbcode;
	croak "Smotif number is required"     unless $smot;
	croak "Loop length of query Smotif is required"   unless $looplen;
	croak "RMSD threshold for clustering is required" unless $threshold;
	croak "Number of Smotifs in the query protein is required" unless $num_mots;

	my $shiftcandsfilename = catfile($pdbcode, "shiftcands$filename".".csv");
	# shiftcandsfilename 1aab/shiftcands1aab_01_8HH.csv
    # my $shiftcandsfilename="$pdbcode/shiftcands$filename".".csv";
	
    open( INFILE3, $shiftcandsfilename) or 
        croak "Unable to open CS comparison file $shiftcandsfilename";

    # print "opening $shiftcandsfilename\n";
    my $line = <INFILE3>;	#ignore header line
	my $check0  =0;
	my %seqlist0;
    my $check = 0;
    my %seqlist;

	#first, read in data and add sequence similarity information to smotifs 
	#(not used currently, but if sequence signals become important, this will be useful
	my @fullarray;
	while (my $line = <INFILE3>) {
		chomp $line ;
        #print "line = $line\n";
		my @lin = split( /\s+/, $line);
		my $val = checkseqblosum( $seq, $lin[5] );
		$line.="\t$val";
		push @fullarray, $line;
	}
	close(INFILE3);
    print Dumper(\@fullarray) if $DEBUG;
    # print Dumper(\@fullarray) ;

	#if (-e $shiftcandsfilename) {unlink $shiftcandsfilename};

	#find maximum loop signature similarity, with the provision that there are at least 20 smotif candidates
	#with at least this level of similarity. Smotifs with less than  level of similarity will be filtered out.
	my $maxloopoverlap = length($seq);
	my $maxnumber = 0;
	my $overallminrmsd = 100;
	my $w_max = 20;   
    if (scalar(@fullarray)<$w_max) { 
        $w_max = scalar @fullarray;
    };
    
    print "maxnumber = $maxnumber w_max = $w_max\n" if $DEBUG;
    while ($maxnumber < $w_max) {
		$maxnumber = 0;
		$maxloopoverlap--;
		for (my $aa = 0; $aa < scalar(@fullarray); $aa++) {
			# my $line = $fullarray[$aa] || undef;
            # next unless $line;
			my $line = $fullarray[$aa];
			
            my @lin  = split(/\s+/, $line);
			if (scalar(@lin)>6) {
				if ($lin[-2]>=$maxloopoverlap) {
					$maxnumber++;
				}
				if ($lin[2]<$overallminrmsd) { 
                    $overallminrmsd = $lin[2]; 
                }
			}
		}
	}
	if ($looplen<4) {$maxloopoverlap--}	#for short loops, need to be more lenient with loop overlap

    # Make two lists: one for diversity and one for population; Diversity has additional filter for candidates
    # with high degree of signature similarity    
    my @fullranks0;
	my @fullranks;
    for (my $aa = 0; $aa < scalar(@fullarray); $aa++ ) {
        my $line = $fullarray[$aa];
        my @lin  = split(/\s+/, $line);
        if (scalar(@lin)>6) {
            $lin[5] =~ s/\"//g;
            unless (exists($seqlist0{$lin[5]})) {
                push @fullranks, [@lin, checkseqblosum($seq, $lin[5]) ] ;
                $check = 1;
                $seqlist{ $lin[5] } = 1;
                if ( ($lin[-2] >= $maxloopoverlap) ) {
                    push @fullranks0, [@lin,checkseqblosum( $seq,$lin[5] ) ] ;
                    $check0 = 1;
                    $seqlist0{ $lin[5] } = 1;
                }
            }
         }
    }

    #print "two lsit\n";
    if ($check0==0 || $check==0) {return } #If, somehow, no smotifs are found in the file

	#Rank both sets by chemical shift difference

	@fullranks0 = sort {$a->[1] <=> $b->[1]} @fullranks0;
    @fullranks  = sort {$a->[1] <=> $b->[1]} @fullranks;
   
    if( $DEBUG ) {
        print "fullranks0\n";
        print Dumper(\@fullranks0);
        print "fullranks\n";
        print Dumper(\@fullranks);
    }

	#find lowest and mean rmsd of the entire filtered set
	my $fullmin = 100;
	my $fullmean= 0;
	for (my $aa = 0; $aa < scalar(@fullranks); $aa++ ) {
		if ( ($fullranks[$aa][2]<$fullmin) ) {
            $fullmin = $fullranks[$aa][2];
        }
		$fullmean += $fullranks[$aa][2];
	}
	$fullmean /= scalar(@fullranks);

	##### To get cluster on the go

	my @newlist = get_cluster_on_the_go($pdbcode, $smot, $threshold, @fullranks);
    if ($DEBUG) {
         print "get_cluster_on_the_go: newlist\n";
         print Dumper(\@newlist);
    }
    #print "get_cluster_on_the_go end\n";
    #print Dumper(\@newlist);

	## Set number of candidates to be selected for enumeration
	my $num_candidates = 4;
	# for smaller proteins, can evaluate more candidates because of combinatorial nature of enumeration
    if ($num_mots < 6) {
        $num_candidates += (6-$num_mots)*2; 
    }

	#Population based selection based on cluster on the go

    my @motlist;		#list of nids
    my @motrmsds;		#list of rmsds
    my @motclust;		#lits of cluster numbers
    my $ab=0;
    while (($ab<$num_candidates) and ($ab<scalar(@newlist))) {
        push ( @motlist, $newlist[$ab][0] );
        push ( @motrmsds,$newlist[$ab][1] );
        push ( @motclust,$newlist[$ab][6] );
        $ab++;
    }

	my $clustercount = scalar(@motlist);

    #####Diversity calculation using Joe's clusters

    my $useclust = 1; #0=select top smotifs, regardless of cluster membership, 
    #1=select only one representative from the top ranked clusters

    $num_candidates = $num_candidates*2;
    my $ac = 0;

    ####Read Joe's clusters

    my %hh0;
    my %nn0;
    my %hhrev0;
    read_joe_clusters(\%hh0,\%nn0,\%hhrev0);
  
    if ($DEBUG){
        print "hh0";
        print Dumper(\%hh0);
        print "nn0";
        print Dumper(\%nn0);
        print "hhrev0";
        print Dumper(\%hhrev0);
    }
    
    # to limit by no of clusters, $clustercount<$num_candidates, otherwise $ac<$num_candidates                   
    while ( ($clustercount<$num_candidates) and ($ac<scalar(@fullranks0)) ) {  
        # need to select only one representative from each cluster
        if ( $useclust == 1 ) {     
            my $new = 1;
            my $currclust0 = $hh0{ $fullranks0[$ac][4] };
            # check to see if a member of the cluster has been chosen already
            CLUSTLOOP:for (my $cc=0;$cc<scalar(@motlist);$cc++) {   #
                if ($hh0{$motlist[$cc]} eq $currclust0) {
                    $new=0;
                    last CLUSTLOOP;
                }       
            }          
            if ($new==1) {
                push @motlist, $fullranks0[$ac][4];
                push @motrmsds,$fullranks0[$ac][2];
                $clustercount++;
            }       
        } 
        else {
            push @motlist, $fullranks0[$ac][4];
            push @motrmsds,$fullranks0[$ac][2];
            $clustercount++;
        }
        $ac++;
    }
    # find lowest and mean rmsd of the selected set
    my $bestmin = 50;
    my $bestmean= 0;
    foreach (@motrmsds) {
        $bestmean += $_/scalar(@motrmsds);;
        if ($_<$bestmin) {$bestmin=$_}
    }
    my $bestmeanprint = sprintf("%.3f",$bestmean);
    my $bestminprint  = sprintf("%.3f",$bestmin);
    my $fullminprint  = sprintf("%.3f",$fullmin);
    my $fullmeanprint = sprintf("%.3f",$fullmean);

    if (DEBUG){ 
    print "$pdbcode\t$smot\t$looplen\t$overallminrmsd\t$fullminprint\t$fullmeanprint\t$bestminprint\t$bestmeanprint\t",    scalar(@motlist),"\n";
    } 

    # 1aab._motifs_rmsd.csv
    print "pdbcode = $pdbcode smot = $smot\n" if DEBUG;
    #                   $pdb."_".$smot."_motifs_best.csv"
    #                   1aab._motifs_rmsd.csv
    my $rmsd = join('', $pdbcode, '_', $smot, '_motifs_rmsd.csv');                                  
    my $best = join('', $pdbcode, '_', $smot, '_motifs_best.csv');
    
    # Print output files
    my $rmsd_path = catfile("$pdbcode", "$rmsd");
    my $best_path = catfile("$pdbcode", "$best");
    
    open(MOTIFRMSDS,">$rmsd_path") 
        or croak "Unable to open output RMSD file for $pdbcode $smot\n";
    
    open(MOTLISTOUT,">$best_path") 
        or croak "Unable to open output BEST file for $pdbcode $smot\n";
    
    print MOTLISTOUT "$filename\t";
    #print "** motlist \n";
    #print Dumper(\@motlist);
    #print "*****\n";
    for (my $aa = 0; $aa <scalar(@motlist); $aa++) {
        print MOTLISTOUT "$motlist[$aa]\t";
        print MOTIFRMSDS "$motlist[$aa]\t$motrmsds[$aa]\t$filename\n";
    }
    print MOTLISTOUT "\n";
    print MOTIFRMSDS "\n";
    close(MOTIFRMSDS);
    close(MOTLISTOUT);
}

=head2 getseq

    Subroutine to get the loop sequence for a given smotif by reading through 
    the <pdbcode>.out file
    
    $filename = 1aab_01_8HH
    $pdbcode  = 1aab

    more 1aab/1aab.out
    Name     Chain   Type  Start   Looplength  SS1length SS2length   Sequence
    1aab.pdb A       HH    14      8           15        12          SYAFFVQTSREEHKKKHPDASVNFSEFSKKCSERW
    1aab.pdb A       HH    37      4           12        22          FSEFSKKCSERWKTMSAKEKGKFEDMAKADKARYEREM

=cut

sub getseq {
    use File::Spec::Functions qw(catfile);
    use Data::Dumper;
    
    my ($filename, $pdbcode) = @_;
	
    croak "4-letter pdbcode is required\n" unless $pdbcode;
	croak "Filename is required\n"         unless $filename;

	my @lin = split(/_/, $filename);
=for    
    print Dumper(\@lin);
    $VAR1 = [
    '1aab',
    '02',
    '4HH'
    ];
=cut    

    # my $newfile="$pdbcode/$lin[0]".".out";
	my $newfile = catfile($pdbcode, "$lin[0]".".out");
	open(INFILE2, $newfile) or die "Unable to open file $newfile $!\n";
	
    my $line;
	for (my $aa = 0; $aa <= $lin[1]; $aa++) {
        $line = <INFILE2>;
    }
	my @lin2 = split(/\s+/, $line);
=for
    @lin2 = (
    '1aab.pdb',
    'A',
    'HH',
    '14',
    '8',
    '15',
    '12',
    'SYAFFVQTSREEHKKKHPDASVNFSEFSKKCSERW'
};
=cut
    # print Dumper(\@lin2);
    close(INFILE2);
	return substr($lin2[7],$lin2[5]-3,$lin2[4]+6);
}

=head2 checkseqblosum

	Subroutine to find the per-residue BLOSUM62 score between two sequences

=cut

sub checkseqblosum {
        my ($native,$test)=@_;
	#croak "Native protein is required\n" unless $native;
	#croak "Test protein is required\n" unless $test;
        my $total=0;
        my %blosum;
        %blosum = ('AA',4,'AR',-1,'AN',-2,'AD',-2,'AC',0,'AQ',-1,'AE',-1,'AG',0,'AH',-2,'AI',-1,'AL',-1,'AK',-1,'AM',-1,'AF',-2,'AP',-1,'AS',1,'AT',0,'AW',-3,'AY',-2,'AV',0,'RR',5,'NR',0,'DR',-2,'CR',-3,'QR',1,'ER',0,'GR',-2,'HR',0,'IR',-3,'LR',-2,'KR',2,'MR',-1,'FR',-3,'PR',2,'RS',-1,'RT',-1,'RW',-3,'RY',-2,'RV',-3,'NN',6,'DN',1,'CN',-3,'NQ',0,'EN',0,'GN',0,'HN',1,'IN',-3,'LN',-3,'KN',0,'MN',-2,'FN',-3,'NP',-2,'NS',1,'NT',0,'NW',-3,'NY',-2,'NV',-3,'DD',6,'CD',-3,'DQ',0,'DE',2,'DG',-1,'DH',-1,'DI',-3,'DL',-4,'DK',-1,'DM',-3,'DF',-3,'DP',-1,'DS',0,'DT',-1,'DW',-4,'DY',-3,'DV',-3,'CC',9,'CQ',-3,'CE',-4,'CG',-3,'CH',-3,'CI',-1,'CL',-1,'CK',-3,'CM',-1,'CF',-2,'CP',-3,'CS',-1,'CT',-1,'CW',-2,'CY',-2,'CV',-1,'QQ',5,'EQ',2,'GQ',-2,'HQ',0,'IQ',-3,'LQ',-2,'KQ',1,'MQ',0,'FQ',-3,'PQ',-1,'QS',0,'QT',-1,'QW',-2,'QY',-1,'QV',-2,'EE',5,'EG',-2,'EH',0,'EI',-3,'EL',-3,'EK',1,'EM',-2,'EF',-3,'EP',-1,'ES',0,'ET',-1,'EW',-3,'EY',-2,'EV',-2,'GG',6,'GH',-2,'GI',-4,'GL',-4,'GK',-2,'GM',-3,'FG',-3,'GP',-2,'GS',0,'GT',-2,'GW',-2,'GY',-3,'GV',-3,'HH',8,'HI',-3,'HL',-3,'HK',-1,'HM',-2,'FH',-1,'HP',-2,'HS',-1,'HT',-2,'HW',-2,'HY',2,'HV',-3,'II',4,'IL',2,'IK',-3,'IM',1,'FI',0,'IP',-3,'IS',-2,'IT',-1,'IW',-3,'IY',-1,'IV',3,'LL',4,'KL',-2,'LM',2,'FL',0,'LP',-3,'LS',-2,'LT',-1,'LW',-2,'LY',-1,'LV',1,'KK',5,'KM',-1,'FK',-3,'KP',-1,'KS',0,'KT',-1,'KW',-3,'KY',-2,'KV',-2,'MM',5,'FM',0,'MP',-2,'MS',-1,'MT',-1,'MW',-1,'MY',-1,'MV',1,'FF',6,'FP',-4,'FS',-2,'FT',-2,'FW',1,'FY',3,'FV',-1,'PP',7,'PS',-1,'PT',-1,'PW',-4,'PY',-3,'PV',-2,'SS',4,'ST',1,'SW',-3,'SY',-2,'SV',-2,'TT',5,'TW',-2,'TY',-2,'TV',0,'WW',11,'WY',2,'VW',-3,'YY',7,'VY',-1,'VV',4);
        my $len=length($native);
        if ($len>length($test)) {$len=length($test)}
        for (my $aa=0;$aa<$len;$aa++) {
                my $aa1=substr($native,$aa,1);
                my $aa2=substr($test,$aa,1);
                my $ind=$aa1.$aa2;
                if ($aa1 gt $aa2) {$ind=$aa2.$aa1};
                if (exists($blosum{$ind})) {$total += $blosum{$ind}};
        }
        return $total/$len;
}

=head2 read_clusters

	Subroutine to read smotif clusters obtained from get_cluster_on_the_go

=cut

sub read_clusters {
    use File::Spec::Functions qw(catfile);

    my ($clusters,$nodes,$clustersrev,$pdbcode,$smot) = @_;
    croak "4-letter pdb code is required"   unless $pdbcode;
    croak "Query Smotif number is required" unless $smot;

    # open(CLUSTERFILE,$pdbcode."/clus_".$smot."/motifclusters0") 
    #   or croak "Unable to open cluster file for $pdbcode $smot\n";
    
    my $cluster_file = catfile( $pdbcode, 'clus_'."$smot", 'motifclusters0');
    print "read_clusters: wants to read cluster_file = $cluster_file\n" if DEBUG;
    
    open my $clusterfile, "<", $cluster_file or 
        die "read_clusters: Unable to open cluster file $cluster_file for $pdbcode $smot $!";
   
   # brinda@everest test_brinda]$cat 1aab/clus_02/motifclusters0
   # Cluster1: 005548
   # Cluster2: 001619
    while (my $line = <$clusterfile> ) {
        chomp $line;
        print "\t".$line."\n" if DEBUG;
        next if $line =~ /^$/;
        next unless $line =~ m/Cluster\d+:/;

        my @lin = split(/\s+/,$line);
        for (my $aa=1; $aa<scalar(@lin); $aa++) {
            $$clusters{$lin[$aa]} = $lin[0];
            $$nodes{$lin[$aa]}    = scalar(@lin)-1;
        }
        $$clustersrev{$lin[0]}=[@lin[1..scalar(@lin)-1]];
    }
    close $clusterfile;
}

=head2 get_clusters

	Subroutine to get clusters using Phylip
=cut

sub get_clusters {
    use File::Spec::Functions qw(catfile catdir);

	my ($pdbcode, $smot, $threshold) = @_;
	croak "4-letter pdb code is required"    unless $pdbcode;
    croak "Query Smotif number is required"  unless $smot;
	croak "RMSD threshold for clustering is required" unless $threshold;

    my $dir = getcwd;
    
    my $phylip_input      = catfile($MOTIFCLUSTERS_PATH, "phylip_input");
    my $pdbcode_clus_smot = catdir($pdbcode, 'clus_'."$smot");
    
    copy( "$phylip_input", "$pdbcode_clus_smot") 
        or die "Copy failed: $!";
    
    my $dir2 = catdir($pdbcode, 'clus_'."$smot");
    chdir $dir2 
        or die "get_clusters: Could not change to $dir2";
    
    unlink "outtree" if -e "outtree";
	
    # my $cmd1 = "$PHYLIP_PATH/$PHYLIP_EXEC < phylip_input > phylip_output";
    my $phylip = catfile($PHYLIP_PATH, $PHYLIP_EXEC); 
    my $cmd1   = "$phylip < phylip_input > phylip_output";
    system $cmd1;
	
    SmotifCS::PhylipParser::findClusters('outfile','infile',$threshold);

    my $in_file = 'motifclusters';
    my $out_file= 'motifclusters0';
    # my $cmd3 = "sed 's/nid_//g' < motifclusters > motifclusters0";
    # system $cmd3;
    # routine to replace sed
    remove_nid($in_file, $out_file);

    chdir($dir);
}

=head2 remove_nid 
     
     It will read a two-column file with format like
     
brinda@everest test_brinda]$head /tmp/motifclusters
Cluster4: nid_376468 
Cluster6: nid_167076 
Cluster7: nid_096416 nid_371611 
Cluster8: nid_343341 
Cluster24: nid_356687 nid_318838 nid_016570 nid_229923 nid_003768 nid_091937 
   
 
    nid_ will removed from the second columns and output will written 
    to an output file with format like:
    
brinda@everest test_brinda]$head /tmp/motifclusters0
Cluster4: 376468 
Cluster6: 167076 
Cluster7: 096416 371611
Cluster8: nid_343341 
Cluster24: 356687 318838 016570 229923 003768 091937
=cut

=for     
        #my @rem = map { 
        #    (my $value = $_) =~ s/nid_//g;
        #    $value
        #} @matches;
        
        # Cluster8: nid_343341 
        # Cluster24: nid_356687 nid_318838 nid_016570 nid_229923 nid_003768 nid_091937 
        
        # my $cluster= ($line =~ /(Cluster\d+:)\s+/)[0];
        
        # If you are after a single match you use a scalar in 
        # list context as the L-VALUE i.e
        #
        # my ($cluster) = $line =~ /(Cluster\d+:)\s+/;
        #
        # Note if you forget the ( ) around $scalar and you get a match 
        # $scalar will contain the integer value 1 so don't forget the ( ). 
        # The ( ) gets you list context which you need.
=cut

sub remove_nid {

    use Data::Dumper;
    my ($infile, $outfile) = @_; 

    die "remove_nid: input_file  is required"    unless $infile;
    die "remove_nid: output_file is required"    unless $outfile;
    die "remove_nid: input_file does not exists" unless -e $infile;

    open my $in , "<", $infile  or die $!; 
    open my $out, ">", $outfile or die $!; 
    while ( my $line = <$in> ) { 
        chomp $line;
        next if $line =~ /^$/;
        
        # Cluster24: nid_356687 nid_318838 nid_016570 nid_229923  
        next unless $line =~ m/Cluster\d+:\s+(nid_\d+)/;
        
        #  find lots of nid_XXXX in a $line and store them into an array (@matches). 
        my @matches  = $line =~ m/\s+(nid_\d+)/g;
        
        # removing nid_ for every array element in @matches
        my @rem = map { s/nid_//g; $_} @matches;
       
        # get "ClusterXX :" from line
        my ($cluster) = $line =~ /(Cluster\d+:)\s+/;
        
        next unless $cluster;
        next unless @rem;
        
        my $nid = join(' ', @rem);
        print "remove_nid for line: $cluster $nid\n" if DEBUG;
        print $out "$cluster $nid\n";
    }   
    close $in  or die $!;
    close $out or die $!;
}    

=head2 read_joe_clusters

	Subroutine to read Joe's Smotif cluster classification (from files)

=cut

sub read_joe_clusters {
    use File::Spec::Functions qw(catfile);
    my ($clusters,$nodes,$clustersrev) = @_;
    
    my @types = qw(HH HE EH EE);
    foreach my $type (@types) {
        # my $filename = "$MOTIFCLUSTERS_PATH/$type\_MotifClusterFile.txt";
        my $filename = catfile($MOTIFCLUSTERS_PATH, "$type".'_MotifClusterFile.txt');
        die "read_joe_clusters $filename does not exists"
            unless -e $filename;
        
        open( CLUSTERFILE, "<$filename" ) 
            or croak "Unable to open cluster file $filename";
        
        while (my $line = <CLUSTERFILE> ) {
            chomp $line;
            # print "read_joe_clusters LINE = $line\n" if DEBUG;
            # print "read_joe_clusters LINE = $line\n";
            my @lin = split(/\s+/, $line);
            for (my $aa=1; $aa<scalar(@lin); $aa++) {
                    $$clusters{$lin[$aa]} = $lin[0];
                    $$nodes{$lin[$aa]}    = scalar(@lin)-1;
            }
            $$clustersrev{$lin[0]} = [ @lin[1..scalar(@lin)-1] ];
        }
        close(CLUSTERFILE);
    }
}

=head2 get_cluster_on_the_go
	
    Subroutine to obtain Smotif clusters from the top 200 Smotifs identified using 
    chemical shift difference. 

	Input: 
	1. 4-letter pdb code (directory where all files in the modeling pipeline are saved). 
	2. Smotif number of the query Smotif under consideration
	3. RMSD threshold for clustering Smotifs (default=2.0 A). 
	4. Array of library Smotifs sorted by chemical shift difference. 

	Output: 
	Array of upto 200 library Smotifs, ranked by a compound score obtained from
	cluster size and chemical shift difference
	
=cut

sub get_cluster_on_the_go {
    use File::Spec::Functions qw(catfile catdir);

	my ($pdbcode, $smot, $threshold, @fullranks) = @_;
	
    croak "4-letter pdb code is required"   unless $pdbcode;
	croak "Query Smotif number is required" unless $smot;
	croak "RMSD threshold for clustering is required" unless $threshold;
	#croak "Sorted array of library Smotifs is required\n" unless @fullranks;	

    my @nidlist;
    my @rmsdlist;
    my @cslist;
    my @overlap;

    my $bb = 200;    #Only top 200 smotifs are taken for clustering
    #my $bb = 5;    #Only top 200 smotifs are taken for clustering
    if ( scalar(@fullranks) < $bb ) {
        $bb = scalar(@fullranks);
    }
    
    for (my $aa = 0; $aa < $bb; $aa++ ) {
        my $lin  = $fullranks[$aa][4];
        my $lin2 = $fullranks[$aa][2];
        my $lin3 = $fullranks[$aa][1];
        my $lin4 = $fullranks[$aa][-3];
        push @nidlist, $lin;      #Get list of top 200 smotifs
        push @rmsdlist,$lin2;
        push @cslist,  $lin3;
        push @overlap, $lin4;
    }
    print "get_cluster_on_the_go ". Dumper(\@nidlist) if DEBUG;
    # print "get_cluster_on_the_go ". Dumper(\@nidlist);

    my $num = scalar(@nidlist);
    my @nidlist0;
    # print "NUM = $num\n";
    
    # Get rmsd distance matrix
    # my $working_dir = $pdbcode."/clus_".$smot;
	my $working_dir = catdir( $pdbcode, 'clus_'."$smot");
    print "working_dir = $working_dir\n" if DEBUG;
	
    unless (-e $working_dir or mkdir $working_dir) {
        croak "Unable to create working directory for clustering $working_dir\n";
    }	
    # mkdir($working_dir) or croak "Unable to create working directory for clustering $working_dir\n";

    # my $tempfile = $pdbcode."/clus_".$smot."/infile";
	my $tempfile = catfile( $pdbcode, 'clus_'."$smot", 'infile');
    open( OUTFILE4,">$tempfile" ) 
        or croak "Unable to open temporary cluster file $tempfile\n";
    
    print OUTFILE4 "$num\n";
	for (my $cc = 0; $cc < $num; $cc++) {
        # print "cc = $cc num = $num\n" if DEBUG;
        print "\tComparing Smotifs number = $cc\n" if $VERBOSE;
        my @rmslist = ();
        my $id0 = sprintf("%06d", $nidlist[$cc]); #pad with zeros
        my $id = "nid_".$id0;
        push(@nidlist0, $id0);
        
        for ( my $dd = 0; $dd < $num; $dd++ ) {
            print "\tdd = $dd num = $num\n" if DEBUG;
            if ($cc == $dd) {
                my $rms = 0;
                #print "$nidlist[$cc]\t$nidlist[$dd]\t$rms\n";
                push(@rmslist,$rms);
            } 
            else {
                print "\tIN the else..\n" if DEBUG;
                #print "\tIN the else..\n";
                my $test = SmotifCS::Protein->new();  # Generate new protein structure
                print Dumper(\$test) if DEBUG;
                
                my $base = SmotifCS::Protein->new();  # Generate new protein structure
                # print "motif = $nidlist[$cc] $nidlist[$dd]\n"; # 5548 1619
                
                #print "adding motif to base\n";
                $base->add_motif( $nidlist[$cc] );
                #print "end adding motif to base\n";
               
                #print "adding motif to test\n";
                $test->add_motif( $nidlist[$dd] );
                #print "end adding motif to test\n";
              
                #print "one_Lnadmark\n"; 
                my @base_lm = $base->one_landmark(-1);
                my @test_lm = $test->one_landmark(-1);
                #print "end one_Lnadmark\n"; 
                
                #print "start if \n"; 
                if ( $test_lm[1] < $base_lm[1] ) {
                    $base->shorten(0,$base_lm[1]-$test_lm[1]);
                };
                if ($test_lm[1]>$base_lm[1]) {
                    $test->shorten(0,$test_lm[1]-$base_lm[1]);
                };
                if ($test_lm[3]-$test_lm[1]<$base_lm[3]-$base_lm[1]) {
                    $base->shorten(-1,$base_lm[3]-$base_lm[1]-$test_lm[3]+$test_lm[1]);
                };
                if ($test_lm[3]-$test_lm[1]>$base_lm[3]-$base_lm[1]) {
                    $test->shorten(-1,$test_lm[3]-$test_lm[1]-$base_lm[3]+$base_lm[1]);
                };
                #print "end if \n"; 
                
                #print "begin rmsd\n"; 
                my $rmsd = $test->rmsd($base);
                #print "end rmsd\n"; 
                
                #print "$nidlist[$cc]\t$nidlist[$dd]\t$rmsd\n";
                push @rmslist, $rmsd;
            }
        }
        my $format1 = ("%10s\t");
        my $format2 = ("%.4f\t" x $num);
        printf OUTFILE4 $format1, $id;
        printf OUTFILE4 $format2, @rmslist;
        print  OUTFILE4 "\n";
    }
    close(OUTFILE4);
    
    #print "Start get_clusters\n";
    # Get the clusters using Phylip
    get_clusters( $pdbcode, $smot, $threshold );
    #print "end get_clusters\n";

	# Read cluster information
    my %hh;
    my %nn;
    my %hhrev;
    read_clusters(\%hh,\%nn,\%hhrev,$pdbcode,$smot);

    # Get new rank from cluster size and chemical shift rank
    my @newlist;

    for (my $aa=0;$aa<$num;$aa++) {  # For top 200 smotifs from CS ranking
        my $currclust = $hh{ $nidlist0[$aa] };     #Identify cluster that the node belongs to
        my $currnode  = $nn{ $nidlist0[$aa] };      #Get cluster size as rank for that node 
        my $newrank   = $num - $aa+$currnode;       #New rank = 200-CS_rank+clus_size
        #print "$nidlist[$aa]\t$rmsdlist[$aa]\t$currclust\t$currnode\t$newrank\n";
        push @{$newlist[$aa]},$nidlist[$aa],$rmsdlist[$aa],$cslist[$aa],$newrank,$num-$aa,$currnode,$currclust,$overlap[$aa];
    }

    @newlist = sort {$b->[3] <=> $a->[3]} @newlist;    #Sort the list based on new rank

=for
	# Clean all temporary files used for clustering
	if (-e "$working_dir/phylip_input") {unlink "$working_dir/phylip_input"};
        if (-e "$working_dir/phylip_output") {unlink "$working_dir/phylip_output"};
        if (-e "$working_dir/infile") {unlink "$working_dir/infile"};
        if (-e "$working_dir/outfile") {unlink "$working_dir/outfile"};
        if (-e "$working_dir/outtree") {unlink "$working_dir/outtree"};
        if (-e "$working_dir/motifclusters") {unlink "$working_dir/motifclusters"};
        if (-e "$working_dir/motifclusters0") {unlink "$working_dir/motifclusters0"};
        rmdir($working_dir) or warn "Unable to remove temporary working directory $working_dir\n"; 
=cut
	
    my $phylip_input = catfile ($working_dir, 'phylip_input');
    unlink "$phylip_input" if -e "$phylip_input";

    my $phylip_output = catfile($working_dir, 'phylip_output');
    unlink "$phylip_output" if -e "$phylip_output";

    my $infile = catfile($working_dir, 'infile');
    unlink "$infile" if -e "$infile";

    my $outfile = catfile($working_dir, 'outfile');
    unlink "$outfile"  if -e "$outfile";

    my $outtree = catfile($working_dir, 'outtree');
    unlink "$outtree" if -e "$outtree" ;

    my $motifclusters = catfile($working_dir, 'motifclusters');
    unlink "$motifclusters" if -e "$motifclusters";

    my $motifclusters0 = catfile($working_dir, 'motifclusters0'); 
    unlink "$motifclusters0" if -e "$motifclusters0";
    
    if (-e $working_dir) { 
        rmdir($working_dir) 
            or warn "Unable to remove temporary working directory $working_dir $!"; 
    }
    # print Dumper(\@newlist);
	return (@newlist);
}

=head1 AUTHOR

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ClusterRankSmotifs


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


=head1 ACKNOWLEDGEMENTS


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

1; # End of ClusterRankSmotifs
