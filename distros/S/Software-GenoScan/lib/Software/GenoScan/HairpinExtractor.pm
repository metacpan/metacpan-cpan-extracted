package Software::GenoScan::HairpinExtractor;

use warnings;
use strict;

require Exporter;

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	extractHairpins
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

my %extractParams = (
	"hsa" => {
		"SEQ_LEN_MIN"    => 40,
		"CG_COMP_MIN"    => 0.2,
		"CG_COMP_MAX"    => 0.8,
		"TR_SIG_MAX"     => 5,
		"STEM_LEN_MIN"   => 20,
		"LOOP_LEN_MAX"   => 20,
		"STEM_BP_PR_MIN" => 0.5,
		"UP_STR_NOR_MAX" => 0.35,
		"UP_LEN_NOR_MAX" => 0.35
	}
);

#Description: Wrapper function for hairpin extraction
#Parameters: (1) Species code, (2) extraction parameter file, (3) output directory, (4) verbose flag, (5) log array
#Return value: None
sub extractHairpins($ $ $ $ $){
	my ($SPECIES_CODE, $HP_EXTRACTION_FILE, $OUTPUT_DIR, $VERBOSE, $logArray) = @_;
	if(! -e $OUTPUT_DIR){
		system("mkdir $OUTPUT_DIR");
	}
	if(! -e "$OUTPUT_DIR/step_3"){
		system("mkdir $OUTPUT_DIR/step_3");
	}
	push(@{$logArray}, "Step 3: extract hairpins\n");
	
	#Retrieve hairpin extraction parameters
	my %params = %{$extractParams{$SPECIES_CODE}};
	if($HP_EXTRACTION_FILE){
		%params = readExtractFile($HP_EXTRACTION_FILE, $VERBOSE);
	}
	my $SEQ_LEN_MIN = $params{"SEQ_LEN_MIN"};
	my $CG_COMP_MIN = $params{"CG_COMP_MIN"};
	my $CG_COMP_MAX = $params{"CG_COMP_MAX"};
	my $TR_SIG_MAX = $params{"TR_SIG_MAX"};
	my $STEM_LEN_MIN = $params{"STEM_LEN_MIN"};
	my $LOOP_LEN_MAX = $params{"LOOP_LEN_MAX"};
	my $STEM_BP_PR_MIN = $params{"STEM_BP_PR_MIN"};
	my $UP_STR_NOR_MAX = $params{"UP_STR_NOR_MAX"};
	my $UP_LEN_NOR_MAX = $params{"UP_LEN_NOR_MAX"};
	
	#Detect folded chunk files
	if(!-e "$OUTPUT_DIR/step_2/folded"){
		die "GenoScan error: Unable to find folded chunk directory\n";
	}
	my @files = split(/\n+/, qx(ls $OUTPUT_DIR/step_2/folded));
	my @foldFiles = grep(/[^~]$/, @files);
	my $numFiles = scalar(@foldFiles);
	if($VERBOSE){
		print("    Extracting hairpins from $numFiles files\n");
	}
	if($numFiles == 0){
		die "GenoScan: No folded chunks, terminating\n";
	}
	push(@{$logArray}, "\tExtracting hairpins from $numFiles files\n");

	#Iterate over all folded chunk files
	my $hpLoopCounter = 0;	#Total number of genomic hairpin terminal loops
	my $numSTL = 0;			#Number of single-terminal loop (STL) hairpins (one terminal loop, hairpin at least 40 nuc in length)
	my $numExtracted = 0;	#Number of STLs passing all extraction criteria
	my $windowCounter;
	my $fileCounter = 0;
	my $flankLen = 75;
	foreach my $file (@foldFiles){
		my %evalHairpinLoops;
		$fileCounter++;
		$windowCounter = 0;
		open(FOLD, "$OUTPUT_DIR/step_2/folded/$file") or die "GenoScan error: Unable to read fold file '$file'\n";
		my @fold = <FOLD>;
		close(FOLD);
		my $numWindows = () = join("", @fold) =~ m/>/g;
		my $extractedFile = $file;
		$extractedFile =~ s/\.folded$/.fasta/;
		open(EXTRACTED, ">$OUTPUT_DIR/step_3/$extractedFile") or die "GenoScan error: Unable to write extracted hairpins file\n";
		
		#Iterate over all windows
		for(my $index = 0; $index < scalar(@fold); $index++){
			if($fold[$index] =~ /^>/){
				$windowCounter++;
				if($VERBOSE){
					print("    Analyzing file $fileCounter/$numFiles, window $windowCounter/$numWindows     \r");
				}
				my $winID = $fold[$index];
				$winID =~ s/\s+$//;
				my $seq = $fold[$index+1];
				my $str = $fold[$index+2];
				$seq =~ s/\s//g;
				$str =~ s/\s//g;
				$str =~ s/\(-?[0-9]+(\.[0-9]+)?\)//;
				my $chr = "";
				if($winID =~ m/chromosome ([0-9XYxy]+)/){
					$chr = $1;
				}
				elsif($winID =~ m/>([0-9A-Za-z]+)/){
					$chr = $1;
				}
				$winID =~ m/pos ([0-9]+)/;
				my $windowStart = $1;
				my @criteriaValues;				#Record of hairpin values for all criteria
			
				#If window contains N, ignore
				if($seq =~ m/N/i){
					next;
				}
			
				#Look for hairpin loop in the middle 50-nuc subwindow
				my @hairpinLoopStartPos;
				my @hairpinLoopEndPos;
				my @hairpinLoopLen;
				my $subwinSize = length($str) - $flankLen * 2;
				my $subWindowStr = substr($str, 75, $subwinSize);
				while($subWindowStr =~ m/\((\.+)\)/g){
					push(@hairpinLoopStartPos, $-[1] + 75);
					push(@hairpinLoopEndPos, $+[1] + 75);
					push(@hairpinLoopLen, length($1));
				}
				my $numHairpinLoops = scalar(@hairpinLoopStartPos);
			
				#If subwindow contains no hairpin loop, ignore
				if($numHairpinLoops == 0){
					next;
				}
			
				#Iterate over all hairpin loops in subwindow
				my @strArray = split("", $str);
				foreach my $index (0 .. scalar(@hairpinLoopStartPos) - 1){
					my $startPos = $hairpinLoopStartPos[$index];
					my $loopLen = $hairpinLoopLen[$index];
					my $endPos = $hairpinLoopEndPos[$index];
					my $chrPos = $windowStart + $startPos;
					if($evalHairpinLoops{"$chr:$chrPos"}){
						next;
					}
					$evalHairpinLoops{"$chr:$chrPos"} = 1;
					$hpLoopCounter++;
				
					#Extend until num nuc in hairpin (nucCount) is 120 nuc or until arm is detected
					my $leftAdjust = 0;
					my $rightAdjust = 0;
					my $hairpinSeqLen = $loopLen;
					my $fivePrime = "";
					my $threePrime = "";
					for(my $distance = 1; $hairpinSeqLen < 120; $distance++){
						my $leftDistance = $distance - $leftAdjust;			#Five-prime distance from loop
						my $rightDistance = $distance - $rightAdjust;		#Three-prime distance from loop
						my $leftIndex = $startPos - $leftDistance;			#Five-prime nuc index
						my $rightIndex = $endPos + $rightDistance;			#Three-prime nuc index
						if($leftIndex == -1 || $rightIndex == 200){
							last;
						}
						my $leftSymbol = $strArray[$leftIndex];
						my $rightSymbol = $strArray[$rightIndex];
						if($leftSymbol eq "(" && $rightSymbol eq ")"){		#Base-pair
							if($hairpinSeqLen == 119){
								last;
							}
							$fivePrime = "P" . $fivePrime;
							$threePrime = $threePrime . "P";
							$hairpinSeqLen += 2;
						}
						elsif($leftSymbol eq "." && $rightSymbol eq "."){	#Unpaired
							if($hairpinSeqLen == 119){
								last;
							}
							$fivePrime = "U" . $fivePrime;
							$threePrime = $threePrime . "U";
							$hairpinSeqLen += 2;
						}
						elsif($leftSymbol eq "." && $rightSymbol eq ")"){	#Unpaired and gap
							$fivePrime = "U" . $fivePrime;
							$threePrime = $threePrime . "-";
							$rightAdjust++;
							$hairpinSeqLen++;
						}
						elsif($leftSymbol eq "(" && $rightSymbol eq "."){	#Gap and unparied
							$fivePrime = "-" . $fivePrime;
							$threePrime = $threePrime . "U";
							$leftAdjust++;
							$hairpinSeqLen++;
						}
						elsif($leftSymbol eq ")" || $rightSymbol eq "("){	#Arm detected
							last;
						}
					}
				
					#Determine hairpin sequence
					my $fiveNumNuc = () = $fivePrime =~ m/[PU]/g;
					my $threeNumNuc = () = $threePrime =~ m/[PU]/g;
					my $hairpinSeq = substr($seq, $startPos - $fiveNumNuc, $fiveNumNuc + $loopLen + $threeNumNuc);
					my $hairpinStr = substr($str, $startPos - $fiveNumNuc, $fiveNumNuc + $loopLen + $threeNumNuc);
				
					#Criteria pass flags
					my $seqLenPass = 0;
					my $cgCompPass = 0;
					my $trSigPass = 0;
					my $stemLenPass = 0;
					my $loopLenPass = 0;
					my $stemBpPrPass = 0;
					my $upStrNorPass = 0;
					my $upLenNorPass = 0;
				
					#Check sequence length
					if($hairpinSeqLen >= $SEQ_LEN_MIN){
						$seqLenPass = 1;
					}
					else{
						next;
					}
					push(@criteriaValues, $hairpinSeqLen);
				
					#Check nucleotide composition
					my $cgComp = () = $hairpinSeq =~ m/[CG]/g;
					$cgComp /= $hairpinSeqLen;
					if($cgComp >= $CG_COMP_MIN && $cgComp <= $CG_COMP_MAX){
						$cgCompPass = 1;
					}
					push(@criteriaValues, $cgComp);
				
					#Check triplet-repeat signal
					my %triplets;
					for(my $index = 0; $index < length($hairpinSeq) - 2; $index++){
						my $tri = substr($hairpinSeq, $index, 3);
						if(!$triplets{$tri}){
							$triplets{$tri}= 1;
						}
						else{
							$triplets{$tri}++;
						}
					}
					my $triSum = 0;
					my $triNum = scalar(keys(%triplets));
					foreach my $tri (keys(%triplets)){
						$triSum += $triplets{$tri};
					}
					my $trSig = $triSum / $triNum;
					if($trSig <= $TR_SIG_MAX){
						$trSigPass = 1;
					}
					push(@criteriaValues, $trSig);
				
					#Check hairpin stem length
					my $stemLen = length($fivePrime);
					if($stemLen >= $STEM_LEN_MIN){
						$stemLenPass = 1;
					}
					push(@criteriaValues, $stemLen);
				
					#Check hairpin loop length
					if($loopLen <= $LOOP_LEN_MAX){
						$loopLenPass = 1;
					}
					push(@criteriaValues, $loopLen);
				
					#Check stem base-pair propensity
					my $numBp = () = $fivePrime =~ m/[P]/g;
					$numBp *= 2;
					my $numNuc = $fiveNumNuc + $threeNumNuc;
					my $stembpProp = $numBp / $numNuc;
					if($stembpProp >= $STEM_BP_PR_MIN){
						$stemBpPrPass = 1;
					}
					push(@criteriaValues, $stembpProp);
				
					#Check number/length of unparied stretches in stem divided by stem length
					my @fiveArray = split("", $fivePrime);
					my $numStretches = 0;
					my $longestStretch = 0;
					my $currentStretch;
					my $lastSymbol = "";
					for(my $fivePos = 0; $fivePos < length($fivePrime); $fivePos++){
						if($lastSymbol ne "U" && ($fiveArray[$fivePos] eq "U" || $fiveArray[$fivePos] eq "-")){
							$lastSymbol = "U";
							$numStretches++;
							$currentStretch = 1;
						}
						elsif($lastSymbol eq "U" && $fiveArray[$fivePos] ne "P"){
							$currentStretch++;
						}
						elsif($lastSymbol eq "U" && $fiveArray[$fivePos] eq "P"){
							$lastSymbol = "P";
							if($currentStretch > $longestStretch){
								$longestStretch = $currentStretch;
							}
						}
					}
					my $upStrNor = $numStretches / length($fivePrime);
					if($upStrNor <= $UP_STR_NOR_MAX){
						$upStrNorPass = 1;
					}
					push(@criteriaValues, $numStretches / length($fivePrime));
					my $upLenNor = $longestStretch / length($fivePrime);
					if($upLenNor <= $UP_LEN_NOR_MAX){
						$upLenNorPass = 1;
					}
					push(@criteriaValues, $longestStretch / length($fivePrime));
				
					#Write hairpin to output files
					my $lociStart = $windowStart + $startPos + 1 - $fiveNumNuc;
					my $lociEnd = $lociStart + $fiveNumNuc + $loopLen + $threeNumNuc;
					if($seqLenPass && $cgCompPass && $trSigPass && $stemLenPass && $loopLenPass && $stemBpPrPass && $upStrNorPass && $upLenNorPass){
						$numExtracted++;
						print(EXTRACTED ">HP$numExtracted species $SPECIES_CODE locus $chr:$lociStart-$lociEnd\n$hairpinSeq\n\n");
					}
					$numSTL++;
				}
			}
		}
		close(FOLD);
	}
	if($VERBOSE){
		print("\n");
	}

	#Write log file (containing num eval hairpins etc.)
	push(@{$logArray}, "\tExtracting hairpins from $numFiles files\n");
	push(@{$logArray}, "\tNumber of genomic hairpins: $hpLoopCounter\n");
	push(@{$logArray}, "\tNumber of single-terminal loop (STL) hairpins: $numSTL\n");
	push(@{$logArray}, "\tNumber of STL hairpins extracted: $numExtracted\n\n");
	close(EXTRACTED);
}

#Description: Reads file with custom hairpin extraction parameters
#Parameters: Extraction parameter file
#Return value: Parameter hash
sub readExtractFile($){
	my ($HP_EXTRACTION_FILE, $VERBOSE) = @_;
	if($VERBOSE){
		print("    Reading extraction parameter file\n");
	}
	open(PARAM, $HP_EXTRACTION_FILE) or die "GenoScan error: Unable to read extraction parameter file\n";
	my $param = join("", <PARAM>);
	close(PARAM);
	$param =~ m/SEQ_LEN_MIN\s*=\s*([0-9.]+)/;
	my $SEQ_LEN_MIN = $1;
	$param =~ m/CG_COMP_MIN\s*=\s*([0-9.]+)/;
	my $CG_COMP_MIN = $1;
	$param =~ m/CG_COMP_MAX\s*=\s*([0-9.]+)/;
	my $CG_COMP_MAX = $1;
	$param =~ m/TR_SIG_MAX\s*=\s*([0-9.]+)/;
	my $TR_SIG_MAX = $1;
	$param =~ m/STEM_LEN_MIN\s*=\s*([0-9.]+)/;
	my $STEM_LEN_MIN = $1;
	$param =~ m/LOOP_LEN_MAX\s*=\s*([0-9.]+)/;
	my $LOOP_LEN_MAX = $1;
	$param =~ m/STEM_BP_PR_MIN\s*=\s*([0-9.]+)/;
	my $STEM_BP_PR_MIN = $1;
	$param =~ m/UP_STR_NOR_MAX\s*=\s*([0-9.]+)/;
	my $UP_STR_NOR_MAX = $1;
	$param =~ m/UP_LEN_NOR_MAX\s*=\s*([0-9.]+)/;
	my $UP_LEN_NOR_MAX = $1;
	my %extParams = (
		"SEQ_LEN_MIN"    => $SEQ_LEN_MIN,
		"CG_COMP_MIN"    => $CG_COMP_MIN,
		"CG_COMP_MAX"    => $CG_COMP_MAX,
		"TR_SIG_MAX"     => $TR_SIG_MAX,
		"STEM_LEN_MIN"   => $STEM_LEN_MIN,
		"LOOP_LEN_MAX"   => $LOOP_LEN_MAX,
		"STEM_BP_PR_MIN" => $STEM_BP_PR_MIN,
		"UP_STR_NOR_MAX" => $UP_STR_NOR_MAX,
		"UP_LEN_NOR_MAX" => $UP_LEN_NOR_MAX
	);
	return %extParams;
}

return 1;

