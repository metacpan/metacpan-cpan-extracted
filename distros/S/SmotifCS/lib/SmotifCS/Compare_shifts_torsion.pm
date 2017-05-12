package SmotifCS::Compare_shifts_torsion;

use 5.10.1 ;
use strict;
use warnings;
use SmotifCS::GeometricalCalculations;
use SmotifCS::Protein;
use SmotifCS::MYSQLSmotifs;
use Data::Dumper;
use Carp;
use File::Spec::Functions qw(catfile);

# use Parallel::ForkManager;

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = "0.1";

    #$AUTHOR  = "Vilas Menon(vilas\@fiserlab.org )";
    @ISA = qw(Exporter);

    # name of the functions to export
    @EXPORT = qw(
	test_motif 
    );

    @EXPORT_OK = qw(
	get_acc_list 
	read_file 	
	comp_shifts 
	match_in_array 
	rand_coil 
	read_ranges 
	weight_table 
	bin 
      );    # symbols to export on request
}
use constant DEBUG => 0;

our @EXPORT_OK;

=head1 NAME

Compare_shifts_torsion 

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Script to compare experimental chemical shift data from a query protein against the database
of smotifs with theoretical chemical shifts. The comparison consists of summing the weighted
squared difference between the chemical shifts of the loop residues and up to 3 flanking
secondary structure residues

INPUT ARGUMENTS
1) $pdb : 4-letter name of the folder where the experimental chemical shift data is stored
2) $havestructure : 0=no solved structure for RMSD comparison, 1=solved structure exists for RMSD comparison
3) $motnum : which smotif of the protein to compare (0=1st smotif, 1=2nd smotif, and so on)

INPUT FILES
In the shift_weights/ folder:
1) tworanges.csv : A tab-delimited file containing the 5%-95% range of values for chemical shifts for each residue
and atom type
2) A set of paired amino acid files (20x20=400 total, ranging from AA to YY) each containing the relative
frequency that a given chemical shift value corresponds to an alpha-helical, beta-strand, or "other" configuration. Each
of these files has a separate distribution for each of the six atom types.

In the <pdbcode> folder:
1) pred<pdbcode>.tab : Standard output file from TALOS+ with estimates of backbone torsion angles
2) <pdbcode>.out : Standard output file from generate_shifts.pl with information about each smotif

OUTPUT FILES
In the <pdbcode> folder:
1) shiftcands<pdbcode><motnum>_<looplength><smotif type>.csv : File containing results of comparing the query smotif
against the database. Includes the number of residues compared, the chemical shift difference value, the RMSD (if structure is included),
the loop length, the smotif NID, the secondary structure RMSD, secondary structure lengths, and loop structural signatures for 
the query and database motif and their overlap.

=cut

# accessing a block of an ini-file;
use Config::Simple;
my $config_file = $ENV{'SMOTIFCS_CONFIG_FILE'};
croak "Environmental variable SMOTIFCS_CONFIG_FILE should be set" unless $config_file;

my $cfg      = new Config::Simple($config_file );
my $cs_db  = $cfg->param(-block=>'chemical_shift_database');

my $TWORANGES_CSV = $cs_db->{'tworanges'};
my $SHIFT_WEIGHTS = $cs_db->{'shift_weights_dir'};
my $MOTIFSHIFTS_DIR=$cs_db->{'motifshifts'};

die "tworanges.csv is required" unless $TWORANGES_CSV;

=head2 test_motif

	Subroutine to compare chemical shifts and torsion angles between a query Smotif and 
	a library Smotif

        test_motif($pdb,$havestructure,$motnum);

	Input arguments
	my $pdb=$ARGV[0];		#folder where the data is stored
	my $havestructure=$ARGV[1]; 	#1=solved structure exists (for RMSD comparison), 0=no solved structure
	my $motnum=$ARGV[2];		#smotif number to compare

=cut
sub test_motif {
        use File::Spec::Functions qw(catfile);
	my ($pdb, $havestructure, $motnum) = @_;

	croak "4-letter pdb code is required" unless $pdb;
	croak "Smotif number is required" unless $motnum;
	$havestructure=0 unless $havestructure;
        
       # die properly and with dignity 
        
        $motnum = $motnum - 1; 
        	
        my %ranges  = read_ranges();	#Get limits for atom- and residue-specific chemical shift values
	my %weights = weight_table();	#Get information about the distribution of chemical shift values for each atom-type within each residue pair
	 
        croak "Could not read ranges"       unless keys %ranges;
        croak "Could not read weight_table" unless keys %weights;
        
        # print Dumper(\%ranges);
        # print Dumper(\%weights);

        #my $ldbh=GeometricalCalculations::connect_to_mysql();	#Connect to smotif database
	
        print "\tConnecting to MySQL DB ...\n";
        SmotifCS::MYSQLSmotifs::connect_to_mysql();	#Connect to smotif database
	my $pdbname=$pdb;
	my $pdbfile;
	if ($havestructure==1) {
		$pdbfile = SmotifCS::GeometricalCalculations::get_full_path_name_for_pdb_code($pdb);
		croak "PDB file for $pdb does not exist" unless ($pdbfile);
	}
	#Get torsional angle data from the TALOS+ output file
	# my $predfile = "$pdb/pred$pdb\.tab";
	my $predfile = catfile($pdb, "pred$pdb.tab");
	open(PREDFILE,"$predfile") or die "Unable to open backbone angle prediction file $predfile\n";
	my %pred;
	my %angtypes;
	my $line=<PREDFILE>;	#ignore header line
	while ($line=<PREDFILE>) {
		chomp($line);
		my @lin=split('\s+',$line);
		$pred{$lin[0]}=[$lin[2],$lin[3],$lin[1]];
		if (($lin[2] < 9000) and ($lin[3] < 9000)) { 
			$angtypes{$lin[0]}=get_acc_list($lin[2],$lin[3]);	#Generate letter code based on Narcis' Ramachandran plot discretization
		} else {$angtypes{$lin[0]}='.'}
	}
	close(PREDFILE);

	#if (-e $predfile) {unlink $predfile};

	#Get information about the putative smotif
	# open(INFILE3,"$pdb/$pdb".".out") or die "no file $pdb to compare shifts\n";
	my $pdb_pdb_out = catfile($pdb, "$pdb.out");
        open(INFILE3,"$pdb_pdb_out") or die "no file $pdb to compare shifts\n";
	$line=<INFILE3>;	#skip header line
	for (my $cc=0;$cc<=$motnum;$cc++) {
		$line=<INFILE3>;
	}
	close(INFILE);
	chomp($line);
	my @lin=split('\s+',$line);
	
        # print Dumper(\@lin);
        my $expseq=$lin[7];
	my $expacclist;								#Generate structural signature for the loop residues of the experimental smotif
	for (my $aa=$lin[3]+$lin[5]-1;$aa<$lin[3]+$lin[5]+$lin[4]+1;$aa++) {
		$expacclist .= $angtypes{$aa};
	}
	
        my $lenlimit=2;								#Leeway for loop length
        if (($lin[5]<3) or ($lin[6]<3)) {$lenlimit=1};

        # Leeway for ss length
 
        my $ss_lenlimit = 3;
        my $list;
	if (($lin[2] eq 'AR') or ($lin[2] eq 'JA') or ($lin[2] eq 'EE')) {
           my $loop_length = $lin[4];
           my $ss1_length  = $lin[5];  
           my $ss2_length  = $lin[6];  
           $list = SmotifCS::MYSQLSmotifs::get_matching_AR_or_JA_smotifs($loop_length, $lenlimit, $ss_lenlimit, $ss1_length, $ss2_length, $pdb);
	} 
        else {
           my $loop_length = $lin[4];
           my $ss1_length  = $lin[5];  
           my $ss2_length  = $lin[6];
           my $type        = $lin[2];  
           $list = SmotifCS::MYSQLSmotifs::get_matching_smotifs($loop_length, $lenlimit, $ss_lenlimit, $ss1_length, $ss2_length, $pdb, $type);  
        }
	#print "This is list:\n";
        #print Dumper($list);
	#get backbone coordinates, if structure exists
	my $base=SmotifCS::Protein->new();
	if ($havestructure==1) {
		$base->add_motif($pdbname,$lin[1],$lin[3],$lin[5],$lin[6],$lin[4],0,$lin[2]);	
	}

	my $shiftnumber = $motnum+1;
	my $name = sprintf("%02d",$shiftnumber);
	
        my $csv_file = catfile($pdb, "shiftcands$pdb"."_".$name."_"."$lin[4]$lin[2]".".csv");
	open(OUTFILE, ">$csv_file" ) or die $!;
	# open(OUTFILE,">$pdb/shiftcands$pdb"."_".$name."_"."$lin[4]$lin[2]".".csv");
	print OUTFILE "Residues compared\tCS difference\tRMSD\tLoop length\tNID\tSequence\tRMSD_SS\tSS1 length\tSS2 length\tSignature\tExp Signature\tSignature overlap\n";

	# print "Comparing experimental shifts to theoretical shifts for each relevant smotif...\n";
	print "\tComparing experimental shifts to theoretical shifts for each relevant smotif. Smotif number = $shiftnumber\n\n";
	#compare experimental shifts to theoretical shifts for each relevant smotif
	#my @list = @$list;
        #LOOP:while (@list) {
        LOOP:foreach my $aref_list (@$list) {
                my @list = @$aref_list;
		if (match_in_array( $list[0],(175869,148692,197460,17231,170186,306955,233467,250889,257044,183472,219018,245161,302970,302958))) {next LOOP}; #missing elements
		if (match_in_array($list[4],qw(3err 2iad 2ji5 2q0i 2ecp 1cu1 1mwa 1ro5 1zua 2hk2 3dh8 1mbq 1yrb 2zji 1pfz 2zjl 2zjj 2f07 2e27 1a4k 1es0 1pum 3d4u 1t7e 1zli 1rp1 1puu 1fl5 1vsn 1ggp 2ph8 1gcj 3bvf 1miq 3duy 1g2b 1t7b 2zjk 1fwx 1axs 3eml 3cbj 3d45 2z5s 1alq 3h9e))) {next LOOP} #non-sequential pdb files
		my $libseq=$list[9];
		if ($libseq =~ /B|J|O|U|X|Z/) {next LOOP};	#non-standard amino acid
		my %startshift;
		my %startweights;
		my %compshift;
		my %compweights;
		my $chemshiftshort=$lin[4]+2;			#number of flanking ss residues to consider (max=3)
		if ($chemshiftshort>3) {$chemshiftshort=3}
		if (($list[7]<0.75*$lin[5]) or ($list[11]<0.75*$lin[6])) {next LOOP}	#ignore smotifs with significantly shorter secondary structures
		if ($lin[5]<$chemshiftshort) {$chemshiftshort=$lin[5]};
		if ($lin[6]<$chemshiftshort) {$chemshiftshort=$lin[6]};
		if ($list[7]<$chemshiftshort) {$chemshiftshort=$list[7]};
		if ($list[11]<$chemshiftshort) {$chemshiftshort=$list[11]};


	        # read in experimental data
		# my $name="$pdb/pdb$pdb"."_shifts$shiftnumber".".dat";
		my $name = catfile($pdb, "pdb$pdb"."_shifts$shiftnumber".".dat");
                eval {
			read_file($name,
				\%startshift,
				\%startweights,
				\%ranges,
				\%weights,
				$lin[5]-$chemshiftshort,
				$lin[5]+$lin[4]+$chemshiftshort-1,
				$expseq
                        );
		};
                if ($@) {
                    croak "Can not read experimental chemical shift in $name $!";
                }

		# read in theoretical data for library smotif
		my $nid = sprintf("%06d", $list[0]); #pad with zeros
		# my $fname="$MOTIFSHIFTS_DIR/$nid"."_shift.dat";
		my $fname = catfile($MOTIFSHIFTS_DIR, $nid."_shift.dat");
		eval {
                    	read_file($fname,
				\%compshift,
				\%compweights,
				\%ranges,
				\%weights,
				$list[7]-$chemshiftshort,
				$list[7]+$list[8]+$chemshiftshort-1,
				$libseq
			);	
                };
                if ($@) {
                    # carp "Can not read theoretical chemical shift in $fname ... processing next Smotif";
                    next LOOP;
                }
              
		if(DEBUG){
                    print "startshift\n";
		    print Dumper(\%startshift);
                    print "compshift\n";
		    print Dumper(\%compshift);
                    print "startweights";
                    print Dumper(\%startweights);
                }
                # compare experimental and library data
		my ($rescount,$composite,%results) = comp_shifts( \%startshift,
							\%compshift,
							0,
							$chemshiftshort+$chemshiftshort+$lin[4],
							\%startweights
						     );
		if(DEBUG){
			print "****\n";
			print Dumper($rescount);
			print Dumper($composite);
			print Dumper(\%results);
			print "****\n";
                }
              
                next LOOP if ($rescount==0);

		#calculate rmsd between experimental smotif and library smotif, if structure exists
		my $rmsd=0;
		my $rmsdss=0;
		if ($havestructure==1) {
			my $test=SmotifCS::Protein->new();
			$test->add_motif($list[0]);
			if ($list[7]<$lin[5]) {$test->elongate(0,$lin[5]-$list[7])}
			if ($list[7]>$lin[5]) {$test->shorten(0,$list[7]-$lin[5])}
			if ($list[8]+$list[11]<$lin[4]+$lin[6]) {$test->elongate(-1,$lin[4]+$lin[6]-$list[8]-$list[11])}
			if ($list[8]+$list[11]>$lin[4]+$lin[6]) {$test->shorten(-1,$list[8]+$list[11]-$lin[4]-$lin[6])}
			$rmsd=$test->rmsd($base);
			$rmsdss=$test->rmsd_ss($base);
		}
		
		#get smotif sequence and structural signature
		my $seq = substr($list[9],$list[7]-3,$lin[4]+6);
		if ($list[7]-3<0) {$seq=substr($list[9],0,$list[8]+2*$list[7])}
		my $acclist=substr($list[12],$list[7]-1,$lin[4]+2);
		
		#find the degree of overlap between the structural signatures of the experimental and library smotifs
		my $common=0;
		for (my $aa=0;$aa<length($acclist);$aa++) {
			if (substr($acclist,$aa,1) eq substr($expacclist,$aa,1)) {$common++}
		}
		
		#print to file
		print OUTFILE "$rescount\t",$composite/$rescount,"\t$rmsd\t$list[8]\t";
		print OUTFILE "$list[0]\t$seq\t$rmsdss\t$list[7]\t$list[11]\t$acclist\t$expacclist\t$common\n";
	}
	close(OUTFILE);
	close(INFILE3);
	SmotifCS::MYSQLSmotifs::disconnect_to_mysql();
}

=head2 get_acc_list

	Subroutine to convert phi-psi angles to a set of 11 structural 
	features (used by Narcis when generating the smotif database

=cut
sub get_acc_list {
	my (@tors)=@_;
	my $phibin=(int(($tors[0]+180)/40)*40)-180;
	my $psibin=(int(($tors[1]+180)/40)*40)-180;
	my %phirows;
	$phirows{-180}{140}='b';
	$phirows{-180}{100}='b';
	$phirows{-180}{60}='b';
	$phirows{-180}{20}='a';
	$phirows{-180}{-20}='a';
	$phirows{-180}{-60}='a';
	$phirows{-180}{-100}='a';
	$phirows{-180}{-140}='e';
	$phirows{-180}{-180}='b';	
	
	$phirows{-140}{140}='b';
	$phirows{-140}{100}='b';
	$phirows{-140}{60}='b';
	$phirows{-140}{20}='a';
	$phirows{-140}{-20}='a';
	$phirows{-140}{-60}='a';
	$phirows{-140}{-100}='a';
	$phirows{-140}{-140}='a';
	$phirows{-140}{-180}='b';

	$phirows{-100}{140}='x';
	$phirows{-100}{100}='x';
	$phirows{-100}{60}='x';
	$phirows{-100}{20}='a';
	$phirows{-100}{-20}='a';
	$phirows{-100}{-60}='a';
	$phirows{-100}{-100}='a';
	$phirows{-100}{-140}='a';
	$phirows{-100}{-180}='x';

	$phirows{-60}{140}='p';
	$phirows{-60}{100}='p';
	$phirows{-60}{60}='p';
	$phirows{-60}{20}='a';
	$phirows{-60}{-20}='a';
	$phirows{-60}{-60}='a';
	$phirows{-60}{-100}='a';
	$phirows{-60}{-140}='a';
	$phirows{-60}{-180}='p';

	$phirows{-20}{140}='o';
	$phirows{-20}{100}='o';
	$phirows{-20}{60}='.';
	$phirows{-20}{20}='.';
	$phirows{-20}{-20}='.';
	$phirows{-20}{-60}='.';
	$phirows{-20}{-100}='.';
	$phirows{-20}{-140}='o';
	$phirows{-20}{-180}='o';

	$phirows{20}{140}='e';
	$phirows{20}{100}='e';
	$phirows{20}{60}='l';
	$phirows{20}{20}='l';
	$phirows{20}{-20}='l';
	$phirows{20}{-60}='l';
	$phirows{20}{-100}='g';
	$phirows{20}{-140}='e';
	$phirows{20}{-180}='e';

	$phirows{60}{140}='e';
	$phirows{60}{100}='e';
	$phirows{60}{60}='v';
	$phirows{60}{20}='v';
	$phirows{60}{-20}='v';
	$phirows{60}{-60}='g';
	$phirows{60}{-100}='g';
	$phirows{60}{-140}='e';
	$phirows{60}{-180}='e';

	$phirows{100}{140}='e';
	$phirows{100}{100}='e';
	$phirows{100}{60}='s';
	$phirows{100}{20}='g';
	$phirows{100}{-20}='g';
	$phirows{100}{-60}='g';
	$phirows{100}{-100}='g';
	$phirows{100}{-140}='e';
	$phirows{100}{-180}='e';

	$phirows{140}{140}='e';
	$phirows{140}{100}='e';
	$phirows{140}{60}='e';
	$phirows{140}{20}='a';
	$phirows{140}{-20}='a';
	$phirows{140}{-60}='a';
	$phirows{140}{-100}='a';
	$phirows{140}{-140}='e';
	$phirows{140}{-180}='e';
	return $phirows{$phibin}{$psibin};
}

=head2 read_file

	Subroutine to read chemical shifts from the file

=cut

sub read_file {	
	my ($nid,$shifts,$shiftweights,$ranges,$weights,$first,$last,$seq)=@_;
	
        open(INFILE,"$nid") or croak "Can not open file $nid $!";
	my $start=-100;
	my %pred=rand_coil();
	LOOP:while (my $line=<INFILE>) {
		my @lin = split(/\s+/, $line);
		if (scalar(@lin)>1) {
			if ($start==-100) {$start=$lin[0]};
			my $countref=$lin[0]-$start;	
			if (($countref<$first) or ($countref>$last)) {next LOOP};	
			my $index=$countref-$first;	#initialize count, so the first desired residue corresponds to index 1
			$index = sprintf("%04d",$index);
			if ($lin[2] =~ /HA/) {$lin[2]='HA'}
			my $hashref=$lin[2].$index;
			my $ref=0;		#Refers to atom type
			$lin[1]=uc($lin[1]);
			if ($lin[2] eq 'CB') {$ref=1}
			elsif ($lin[2] eq 'C') {$ref=2}
			elsif ($lin[2] eq 'H') {$ref=3}
			elsif ($lin[2] eq 'HA') {$ref=4}
			elsif ($lin[2] eq 'N') {$ref=5}
			my $rref=$lin[1].$lin[2];
			if ($pred{$lin[1]}[$ref] eq 0) {
				$$shifts{$hashref}=0;
				$$shiftweights{$hashref}=0;
			} else {
				my $val=($lin[3]-$pred{$lin[1]}[$ref]);	#Subtract off random coil value (not elegant, but distribution files were set up this way)
				my $rref2;
				#for N and amide H chemical shifts, distribution is dependent on the current and previous residue type
				if (($lin[2] eq 'N') or ($lin[2] eq 'H')) {
					if ($countref==0) {next LOOP}
					$rref2=substr($seq,$countref-1,2);
				}
				#for carbonyl C chemical shifts, distribution is dependent on the current and next residue type
				if ($lin[2] eq 'C') {
					if ($countref==length($seq)-1) {next LOOP}
					$rref2=substr($seq,$countref,2);
				}
				#for beta-carbon, alpha-hydrogen, and alpha-carbon shifts, distribution is dependent on the current and previous residue type, unless they are in the first residue
				if (($lin[2] eq 'CB') or ($lin[2] eq 'HA') or ($lin[2] eq 'CA')) {
					if ($countref==0) {$rref2=$rref2.substr($seq,0,2)}
					else {$rref2=substr($seq,$countref-1,2)};
				}
				my $rangeref=$rref2.$lin[2];
				$$shifts{$hashref}=($val-$$ranges{$rangeref}[0])/($$ranges{$rangeref}[1]-$$ranges{$rangeref}[0]);	#normalized chemical shift value
				#find bin in which the normalized value falls, and then calculate the weight, defined as the difference between the greatest and second-greatest
				#frequencies within that bin
				my $bv=sprintf("%.5f",bin($val,$$ranges{$rangeref}[2],$$ranges{$rangeref}[0]));
				if (exists($$weights{$rref2.'_'.$lin[2].'_a_'.$bv})) {
					my @props=($$weights{$rref2.'_'.$lin[2].'_a_'.$bv},$$weights{$rref2.'_'.$lin[2].'_b_'.$bv},$$weights{$rref2.'_'.$lin[2].'_c_'.$bv});
					@props=sort {$b <=> $a} @props;
					$$shiftweights{$hashref}=$props[0]-$props[1];
				} else {
					$$shiftweights{$hashref}=0;
				}

			}
		} else {last LOOP}
	}
	close (INFILE);

}

=head2 comp_shifts

	Subroutine to compare two sets of chemical shifts 
	by calculating the average weighted sum of squared differences

=cut

sub comp_shifts {
	my ($shift1,$shift2,$startnum,$num,$weightsq)=@_;

	#get the full list of atom types from the first set of shifts to be compared
	my @keylist;
	for my $key (keys %$shift1) {
		if ($key =~/(\D+)\d+/) {
			my $new=$1;
			if (match_in_array($new,@keylist)==0) {push(@keylist,$new)}
		}
	}
	my %results;
	my $composite=0;
	my $composite2=0;
	my $rescount=0;
	
	#find the difference between each set of hash keys that show up in both sets of chemical shifts, implying they are to be compared directly
	LOOP:for (my $aa=$startnum;$aa<$num;$aa++) {
		my $total=0;
		my $count=0;
		my $index=sprintf("%04d",$aa);
		foreach my $type (@keylist) {
			my $hashref=$type.$index;
			if (exists($$shift1{$hashref})) {
				if (exists($$shift2{$hashref})) {
					if (($$shift1{$hashref} ne 0) and ($$shift2{$hashref} ne 0)) {
						$total += (abs($$shift1{$hashref}-$$shift2{$hashref}))*$$weightsq{$hashref};
						$count++;
					}
				}
			}
		}
		if ($count>0) {	#there was a matching set of residues to be compared
			$results{$aa}=$total/$count;
			$composite2 += $total/$count;
			$rescount++;
		}
		
	}
	return ($rescount,$composite2,%results);
}
				
=head2 match_in_array

	Subroutine to find if a scalar element appears in an array

=cut

sub match_in_array {
	my ($query,@array)=@_;
	foreach (@array) {
		if ($query eq $_) {return 1}
	}
	return 0;
}

=head2 rand_coil

	Subroutine to generate a hash with the random coil 
	values for backbone atoms (data from NMRPipe)

=cut
sub rand_coil {
	my %pred;
	#alpha carbon, beta carbon, carbonyl carbon, amide hydrogen, alpha hydrogen, nitrogen) - data from NMRPipe
	$pred{'A'}=[52.30,19.00,177.80,8.15,4.32,124.20];
	$pred{'C'}=[0.00,0.00,0.00,0.00,0.00,0.00];
	$pred{'D'}=[54.00,40.80,176.30,8.37,4.64,120.40];
	$pred{'E'}=[56.40,29.70,176.60,8.36,4.35,120.20];
	$pred{'F'}=[58.00,39.00,175.80,8.30,4.62,120.30];
	$pred{'G'}=[45.10,00.00,174.90,8.29,3.96,108.80];
	$pred{'H'}=[54.50,27.90,173.30,8.28,4.73,118.20];
	$pred{'I'}=[61.30,38.00,176.40,8.21,4.17,119.90];
	$pred{'K'}=[56.50,32.50,176.60,8.25,4.32,120.40];
	$pred{'L'}=[55.10,42.30,177.60,8.23,4.34,121.80];	
	$pred{'M'}=[55.30,32.60,176.30,8.29,4.48,119.60];
	$pred{'N'}=[52.80,37.90,175.20,8.38,4.74,118.70];
	$pred{'P'}=[63.10,31.70,177.30,0.00,4.42,135.80];
	$pred{'Q'}=[56.10,28.40,176.00,8.27,4.34,119.80];
	$pred{'R'}=[56.10,30.30,176.30,8.27,4.34,120.50];
	$pred{'S'}=[58.20,63.20,174.60,8.31,4.47,115.70];
	$pred{'T'}=[62.10,69.20,174.70,8.24,4.35,113.60];
	$pred{'V'}=[62.30,32.10,176.30,8.19,4.12,119.20];
	$pred{'W'}=[57.70,30.30,176.10,8.18,4.66,121.30];
	$pred{'Y'}=[58.10,38.80,175.90,8.28,4.55,120.30];
	return %pred;
}

=head2 read_ranges

	Subroutine to read values for the ranges for chemical 
	shift values for each atom- and residue-type (from a file)

=cut

sub read_ranges {
	my %ranges;
	#open(INFILE,"/home/afiser/brinda/from_vilas/shift_weights/tworanges.csv") or die "no range file tworanges.csv\n";
	open(INFILE, $TWORANGES_CSV) or die "no range file $TWORANGES_CSV\n";
	while (my $line=<INFILE>) {
		chomp($line);
		my @lin = split(/\s+/, $line);
		$ranges{$lin[0].$lin[1]}=[$lin[2],$lin[3],$lin[4]];
	}
	close(INFILE);
	return %ranges;
}

=head2 weight_table

	Subroutine to read values for the frequencies of 
	chemical shift values in alpha-, beta-, or other configurations (from a file)

=cut
sub weight_table {
        use File::Spec::Functions qw(catfile);
	
        my %weights;
	my @res = ('A','C','D','E','F','G','H','I','K','L','M','N','P','Q','R','S','T','V','W','Y');
	my @twores;
	foreach my $res (@res) {
		foreach my $res2 (@res) {
			push(@twores,"$res"."$res2");
		}
	}
	
        # my @types=('C_a','C_b','C_c','CA_a','CA_b','CA_c','CB_a','CB_b','CB_c','H_a','H_b','H_c','HA_a','HA_b','HA_c','N_a','N_b','N_c');
	foreach my $r (@twores) {
	    my $file = catfile($SHIFT_WEIGHTS, "$r.csv");
	    # my $file = "$SHIFT_WEIGHTS/$r.csv";
            open(INFILE, $file ) or croak "Could not open $file $!";
		my @binvals;
		while (my $line=<INFILE>) {
			if ($line =~ /binval/) {
				chomp($line);
				@binvals = split(/\s+/, $line);
				$line = <INFILE>;
				chomp($line);
				my @lin = split(/\s+/, $line);
				if ($lin[0] =~ /(.+\_)bp/) {
					$lin[0] = $1.'b';
				}
				if ($lin[0] =~ /(.+\_)cc/) {
					$lin[0] = $1.'c';
				}
				for (my $aa=1;$aa<scalar(@lin);$aa++) {
					$weights{$r.'_'.$lin[0].'_'.$binvals[$aa]}=$lin[$aa];
				}
			}
		}
		close(INFILE);
	}
	return %weights;
}

=head2 bin
	
	Subroutine to bin a value based on an increment

=cut

sub bin {
	my($val,$inc,$start)=@_;
	my $tmp=($val-$start)/$inc;
	return $start+(int($tmp)*$inc);
}

=head1 AUTHOR

Fiserlab Members , C<< <andras at fiserlab.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Compare_shifts_torsion


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

1; # End of Compare_shifts_torsion
