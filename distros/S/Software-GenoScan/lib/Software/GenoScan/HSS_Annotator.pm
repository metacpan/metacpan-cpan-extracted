package Software::GenoScan::HSS_Annotator;

use warnings;
use strict;

require Exporter;

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	annotateHSS
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

#        HSS notation
#
#Structure elements
#
#Tail                      (T)
#Hairpin loop              (H)
#Watson-Crick basepair     (P)
#U-G wobble                (W)
#Symmetric internal loop   (S)
#Asymmetric internal loop  (A)
#Bulge                     (B)
#
#Regions
#
#stem                      (S)
#hairpin loop              (L)

my $TAIL = "T";
my $BASEPAIR = "P";
my $WOBBLE = "W";
my $SYMMETRIC_LOOP = "S";
my $ASYMMETRIC_LOOP = "A";
my $BULGE = "B";
my $HAIRPIN_LOOP = "H";
my $STEM = "S";
my $TERMINAL_LOOP = "L";

#Description: Wrapper function for hairpin annotation
#Parameters: Visualized hairpins file, (2) output file name
#Return value: None
sub annotateHSS($ $){
	my ($inputFile, $outputFile) = @_;

	open(MIRNA, "$inputFile") or die "GenoScan error: Unable to read '$inputFile'\n";
	my @mirnas = split(/>/, join("", <MIRNA>));
	shift(@mirnas);
	close(MIRNA);
	open(ANNOT, ">$outputFile") or die "GenoScan error: Unable to write '$outputFile'\n";

	foreach my $mir (@mirnas){
		$mir =~ m/^([^\s]+)/;
		my $name = $1;
		$mir = ">$mir";
	
		#Extract visual secondary structure
		my @visual = split(/\n/, $mir);
		my $header = shift(@visual);
		my $seq = shift(@visual);
		my $str = shift(@visual);
		$str =~ m/(\s*-?[0-9]+(\.[0-9]+)?)/;
		my $MFE = $1;
		$str =~ s/\s*\(\s*-?[0-9]+(\.[0-9]+)?\s*\)//;
		shift(@visual);
		my @visualMatrix;
		foreach my $row (@visual){
			my @cols = split(//, $row);
			push(@visualMatrix, \@cols);
		}
	
		#Determine hairpin loop position
		my $numLoops = () = $str =~ m/(\(\.+\))/g;
		my $hairpinLoopLength = length($1) - 2;
		my $hairpinLoopStart = index($str, $1) + 2;
		my $hairpinLoopEnd = $hairpinLoopStart + $hairpinLoopLength - 1;
		
		#Derive region annotation
		my $nucIndex = 0;
		my @regions;
		for(my $pos = 3; $pos < scalar(@{$visualMatrix[0]}) - 2; $pos++){
			if($visualMatrix[0][$pos] =~ m/[AUCG]/i || $visualMatrix[1][$pos] =~ m/[AUCG]/i){
				$nucIndex++;
			}
			if($nucIndex < $hairpinLoopStart){
				push(@regions, $STEM);
			}
		}
		if($hairpinLoopLength == 3){
			push(@regions, $TERMINAL_LOOP);
			push(@regions, $TERMINAL_LOOP);
		}
		elsif($hairpinLoopLength % 2 == 0){
			foreach my $pos (1 .. ($hairpinLoopLength - 2) / 2 + 1){
				push(@regions, $TERMINAL_LOOP);
			}
		}
		elsif($hairpinLoopLength % 2 != 0){
			foreach my $pos (1 .. ($hairpinLoopLength - 3) / 2 + 1){
				push(@regions, $TERMINAL_LOOP);
			}
		}
	
		#Derive structure annotation
		my @structure;
		my $tailPassed = 0;
		$nucIndex = 0;
		for(my $pos = 3; $pos < scalar(@{$visualMatrix[0]}) - 2; $pos++){
			if($visualMatrix[0][$pos] =~ m/[AUCG]/i || $visualMatrix[1][$pos] =~ m/[AUCG]/i){
				$nucIndex++;
			}
			if(!$tailPassed){										#Tail
				if($visualMatrix[2][$pos] eq "|"){
					$tailPassed = 1;
				}
				else{
					push(@structure, $TAIL);
				}
			}
			if($tailPassed && $nucIndex < $hairpinLoopStart){		#Stem passed the tail
				if($visualMatrix[2][$pos] eq "|"){						#Basepair or wobble
					if(($visualMatrix[1][$pos] =~ m/G/i && $visualMatrix[3][$pos] =~ m/U/i) || ($visualMatrix[1][$pos] =~ m/U/i && $visualMatrix[3][$pos] =~ m/G/i)){
						push(@structure, $WOBBLE);
					}
					else{
						push(@structure, $BASEPAIR);
					}
				}
				else{													#Symmetric/asymmetric loop or bulge
					my $mismatchSpan = 0;
					my $mismatchType;
				
					#Find length of mismatch
					for(my $lookAhead = 0; $nucIndex + $lookAhead < $hairpinLoopStart; $lookAhead++){
						if($visualMatrix[2][$pos+$lookAhead] eq "|"){
							last;
						}
						else{
							$mismatchSpan++;
						}
					}
				
					#Find type of mismatch
					my $fivePrime = "";
					my $threePrime = "";
					foreach my $mismatch (0 .. $mismatchSpan - 1){
						$fivePrime .= $visualMatrix[0][$pos+$mismatch];
						$threePrime .= $visualMatrix[4][$pos+$mismatch];
					}
					my $fiveNuc = () = $fivePrime =~ m/[AUGC]/ig;
					my $fiveNucComp = 0;
					if($fivePrime =~ m/^[AUGC]/i){
						$fiveNucComp = 1;
					}
					if($fivePrime =~ m/^[AUGC]+$/i && $threePrime =~ m/^[AUGC]+$/i){
						$mismatchType = "sym";
					}
					elsif(($fivePrime =~ m/^[AUGC]+$/i && $threePrime =~ m/[AUGC]/i && $threePrime =~ m/-/) || ($fivePrime =~ m/[AUGC]/i && $fivePrime =~ m/-/ && $threePrime =~ m/^[AUGC]+$/i)){
						$mismatchType = "asym";
					}
					elsif(($fivePrime =~ m/^[AUGC]+$/i && $threePrime =~ m/^-+$/) || ($fivePrime =~ m/^-+$/ && $threePrime =~ m/^[AUGC]+$/i)){
						$mismatchType = "bulge";
					}
				
					#Add mismatch to @structure
					foreach my $mismatch (1 .. $mismatchSpan){
						if($mismatchType eq "sym"){			#Symmetric loop
							push(@structure, $SYMMETRIC_LOOP);
						}
						elsif($mismatchType eq "asym"){		#Asymmetric loop
							push(@structure, $ASYMMETRIC_LOOP);
						}
						elsif($mismatchType eq "bulge"){	#Bulge
							push(@structure, $BULGE);
						}
					}
					$pos += $mismatchSpan - 1;
					$nucIndex += $fiveNuc - $fiveNucComp;
				}
			}
			elsif($tailPassed && $nucIndex >= $hairpinLoopStart){	#Hairpin loop
				push(@structure, $HAIRPIN_LOOP);
			}
		}
	
		#Add region and structure annotation to miRNA
		$mir .= "   " . join("", @regions) . "\n   " . join("", @structure) . "\n\n";
		my $stem = "";
		my $loop = "";
		my $currentRegion = "STEM";
		foreach my $index (0 .. scalar(@structure) - 1){
			if($regions[$index] eq $TERMINAL_LOOP){
				$currentRegion = "LOOP"
			}
			if($currentRegion eq "STEM"){
				$stem .= $structure[$index];
			}
			elsif($currentRegion eq "LOOP"){
				$loop .= $structure[$index];
			}
		}
		print(ANNOT $mir);
	}
	close(ANNOT);
}

return 1;

