package Software::GenoScan::FoldVisualizer;

use warnings;
use strict;

require Exporter;

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	visualizeFold
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

#Description: Wrapper function for hairpin visualization
#Parameters: (1) Extracted hairpins file, (2) output file name
#Return value: None
sub visualizeFold($ $){
	my ($inputFile, $outputFile) = @_;
	
	open(MIRNA, $inputFile) or die "GenoScan error: Unable to read '$inputFile'\n";
	my @mirnas = split(/>/, join("", <MIRNA>));
	shift(@mirnas);
	close(MIRNA);
	open(OUTPUT, ">$outputFile") or die "GenoScan error: Unable to write '$outputFile'\n";

	#annotations (FP = 5', TP = 3')
	my $FP_STEM_BASEPAIR = "fp_stem_basepair";
	my $FP_STEM_UNPAIRED = "fp_stem_unpaired";
	my $FP_STEM_GAP = "fp_stem_gap";
	my $HAIRPIN_LOOP_TOP = "hairpin_loop_top";
	my $HAIRPIN_LOOP_SIDE1 = "hairpin_loop_side1";
	my $HAIRPIN_LOOP_SIDE2 = "hairpin_loop_side2";
	my $HAIRPIN_LOOP_SIDE3 = "hairpin_loop_side3";
	my $HAIRPIN_LOOP_BOTTOM = "hairpin_loop_bottom";
	my $TP_STEM_BASEPAIR = "tp_stem_basepair";
	my $TP_STEM_UNPAIRED = "tp_stem_unpaired";
	my $TP_STEM_GAP = "tp_stem_gap";

	my $FP_ARM_LEFT_BASEPAIR = "fp_arm_left_basepair";
	my $FP_ARM_RIGHT_BASEPAIR = "fp_arm_right_basepair";
	my $FP_ARM_LEFT_UNPAIRED = "fp_arm_left_unpaired";
	my $FP_ARM_RIGHT_UNPAIRED = "fp_arm_right_unpaired";
	my $FP_ARM_LEFT_GAP = "fp_arm_left_gap";
	my $FP_ARM_RIGHT_GAP = "fp_arm_right_gap";
	my $FP_ARM_LEFT_LOOP = "fp_arm_left_loop";
	my $FP_ARM_RIGHT_LOOP = "fp_arm_right_loop";
	my $FP_ARM_TOP1_LOOP = "fp_arm_top1_loop";
	my $FP_ARM_TOP2_LOOP = "fp_arm_top2_loop";
	my $FP_ARM_TOP3_LOOP = "fp_arm_top3_loop";

	my $TP_ARM_LEFT_BASEPAIR = "tp_arm_left_basepair";
	my $TP_ARM_RIGHT_BASEPAIR = "tp_arm_right_basepair";
	my $TP_ARM_LEFT_UNPAIRED = "tp_arm_left_unpaired";
	my $TP_ARM_RIGHT_UNPAIRED = "tp_arm_right_unpaired";
	my $TP_ARM_LEFT_GAP = "tp_arm_left_gap";
	my $TP_ARM_RIGHT_GAP = "tp_arm_right_gap";
	my $TP_ARM_LEFT_LOOP = "tp_arm_left_loop";
	my $TP_ARM_RIGHT_LOOP = "tp_arm_right_loop";
	my $TP_ARM_BOTTOM1_LOOP = "tp_arm_bottom1_loop";
	my $TP_ARM_BOTTOM2_LOOP = "tp_arm_bottom2_loop";
	my $TP_ARM_BOTTOM3_LOOP = "tp_arm_bottom3_loop";

	foreach my $mir (@mirnas){
		$mir = ">$mir";
		my ($name, $seq, $strRow) = split("\n", $mir);
		my $str = $strRow;
		$str =~ s/\s*\(\s*-?[0-9]+(\.[0-9]+)?\s*\)//;
	
		#find hairpin loop
		my $numLoops = () = $str =~ m/(\(\.+\))/g;
		print(OUTPUT "$mir");
		my $hairpinLoopLength = length($1) - 2;
		my $hairpinLoopStart = index($str, $1) + 1;
		my $hairpinLoopEnd = $hairpinLoopStart + $hairpinLoopLength - 1;
	
		#derive nucleotide annotation
		my @structure = split("", $str);	#secondary structure in "( . )" notation
		my @sequence = split("", $seq);		#sequence in nucleotides
		my @annotation;						#annotation for each nucleotide
	
		#annotate hairpin loop
		if($hairpinLoopLength == 1){
			push(@annotation, $HAIRPIN_LOOP_SIDE2);
		}
		elsif($hairpinLoopLength == 2){
			push(@annotation, $HAIRPIN_LOOP_SIDE1);
			push(@annotation, $HAIRPIN_LOOP_SIDE3);
		}
		elsif($hairpinLoopLength == 3){
			push(@annotation, $HAIRPIN_LOOP_TOP);
			push(@annotation, $HAIRPIN_LOOP_SIDE2);
			push(@annotation, $HAIRPIN_LOOP_BOTTOM);
		}
		elsif($hairpinLoopLength == 4){
			push(@annotation, $HAIRPIN_LOOP_TOP);
			push(@annotation, $HAIRPIN_LOOP_SIDE1);
			push(@annotation, $HAIRPIN_LOOP_SIDE3);
			push(@annotation, $HAIRPIN_LOOP_BOTTOM);
		}
		elsif($hairpinLoopLength >= 5){
			if($hairpinLoopLength % 2 == 0){
				my $extend = ($hairpinLoopLength - 2) / 2;
				foreach my $pos (0 .. $extend-1){
					push(@annotation, $HAIRPIN_LOOP_TOP);
				}
				push(@annotation, $HAIRPIN_LOOP_SIDE1);
				push(@annotation, $HAIRPIN_LOOP_SIDE3);
				foreach my $pos (0 .. $extend-1){
					push(@annotation, $HAIRPIN_LOOP_BOTTOM);
				}
			}
			else{
				my $extend = ($hairpinLoopLength - 3) / 2;
				foreach my $pos (0 .. $extend-1){
					push(@annotation, $HAIRPIN_LOOP_TOP);
				}
				push(@annotation, $HAIRPIN_LOOP_SIDE1);
				push(@annotation, $HAIRPIN_LOOP_SIDE2);
				push(@annotation, $HAIRPIN_LOOP_SIDE3);
				foreach my $pos (0 .. $extend-1){
					push(@annotation, $HAIRPIN_LOOP_BOTTOM);
				}
			}
		}
	
		#annotate left and right
		my $leftAdjust = 0;
		my $rightAdjust = 0;
		my $leftArm = 0;
		my $rightArm = 0;
		my $fpArmFill = 0;
		my $tpArmFill = 0;
		for(my $distance = 1; 1 == 1; $distance++){
			my $leftSymbol;
			my $rightSymbol;
			my $leftDistance = $hairpinLoopStart - ($distance - $leftAdjust + $leftArm);
			my $rightDistance = $hairpinLoopEnd + $distance - $rightAdjust + $rightArm;
			if($leftDistance < 0){
				$leftSymbol = "";
			}
			else{
				$leftSymbol = $structure[$leftDistance];
			}
			if($rightDistance > scalar(@structure) - 1){
				$rightSymbol = "";
			}
			else{
				$rightSymbol = $structure[$rightDistance];
			}
			if(!$leftSymbol && !$rightSymbol){
				last;
			}
			if($fpArmFill > 0 && $tpArmFill > 0){
				$fpArmFill--;
				$tpArmFill--;
			}
			elsif($fpArmFill > 0){
				if($leftSymbol eq "."){
					unshift(@annotation, $FP_STEM_UNPAIRED);
					$rightAdjust++;
					$fpArmFill--;
					next;
				}
				elsif($leftSymbol eq "("){
					unshift(@annotation, $FP_STEM_GAP);
					$rightAdjust++;
					$leftAdjust++;
					$fpArmFill--;
					next;
				}
			}
			elsif($tpArmFill > 0){
				if($rightSymbol eq "."){
					push(@annotation, $TP_STEM_UNPAIRED);
					$leftAdjust++;
					$tpArmFill--;
					next;
				}
				elsif($rightSymbol eq ")"){
					push(@annotation, $TP_STEM_GAP);
					$rightAdjust++;
					$leftAdjust++;
					$tpArmFill--;
					next;
				}
			}
		
			#( with )
			if($leftSymbol eq "(" && $rightSymbol eq ")"){
				unshift(@annotation, $FP_STEM_BASEPAIR);
				push(@annotation, $TP_STEM_BASEPAIR);
			}
		
			#. with .
			elsif($leftSymbol eq "." && $rightSymbol eq "."){
				unshift(@annotation, $FP_STEM_UNPAIRED);
				push(@annotation, $TP_STEM_UNPAIRED);
			}
		
			#( with .
			elsif($leftSymbol eq "(" && $rightSymbol eq "."){
				unshift(@annotation, $FP_STEM_GAP);
				push(@annotation, $TP_STEM_UNPAIRED);
				$leftAdjust++;
			}
		
			#. with )
			elsif($leftSymbol eq "." && $rightSymbol eq ")"){
				unshift(@annotation, $FP_STEM_UNPAIRED);
				push(@annotation, $TP_STEM_GAP);
				$rightAdjust++;
			}
		
			#tail: $left = ""
			elsif(!$leftSymbol && $rightSymbol){
				unshift(@annotation, $FP_STEM_GAP);
				push(@annotation, $TP_STEM_UNPAIRED);
			}
		
			#tail: $right = ""
			elsif($leftSymbol && !$rightSymbol){
				unshift(@annotation, $FP_STEM_UNPAIRED);
				push(@annotation, $TP_STEM_GAP);
			}
		
			#arm: $left = )
			elsif($leftSymbol eq ")"){
				my $armStart = $leftDistance;	#position of first ) in 5' arm
				my $armEnd;						#position of last ( in 5' arm
				my $armOpen = 0;				#number of )
				my $armClose = 0;				#number of (
				my $closeReached = 0;			#end of arm loop has been seen
				my $loopLeft;					#position of first ( left of arm loop
				my $loopRight;					#position of first ) right of arm loop
				my @armAnnot;
			
				#walk left across the arm to determine its length
				for(my $index = $armStart; 1 == 1; $index--){
					if(!$closeReached){
						if($structure[$index] eq ")"){
							$armOpen++;
						}
						elsif($structure[$index] eq "("){
							$closeReached = 1;
							$armClose++;
							$loopLeft = $index;
							my $loop = 1;
							while($structure[$index+$loop] eq "."){
								$loop++;
							}
							$loopRight = $index + $loop;
						}
					}
					else{
						if($armOpen == $armClose){
							$armEnd = $index + 1;
							last;
						}
						elsif($structure[$index] eq "("){
							$armClose++;
						}
					}
				}
			
				#annotate arm loop
				my $loopLength = $loopRight - $loopLeft - 1;
				if($loopLength == 1){
					push(@armAnnot, $FP_ARM_TOP2_LOOP);
				}
				elsif($loopLength == 2){
					push(@armAnnot, $FP_ARM_TOP1_LOOP);
					push(@armAnnot, $FP_ARM_TOP3_LOOP);
				}
				elsif($loopLength == 3){
					push(@armAnnot, $FP_ARM_LEFT_LOOP);
					push(@armAnnot, $FP_ARM_TOP2_LOOP);
					push(@armAnnot, $FP_ARM_RIGHT_LOOP);
				}
				elsif($loopLength == 4){
					push(@armAnnot, $FP_ARM_LEFT_LOOP);
					push(@armAnnot, $FP_ARM_TOP1_LOOP);
					push(@armAnnot, $FP_ARM_TOP3_LOOP);
					push(@armAnnot, $FP_ARM_RIGHT_LOOP);
				}
				elsif($loopLength >= 5){
					if($loopLength % 2 == 0){
						my $extendLoop = ($loopLength - 2) / 2;
						foreach my $pos (0 .. $extendLoop-1){
							push(@armAnnot, $FP_ARM_LEFT_LOOP);
						}
						push(@armAnnot, $FP_ARM_TOP1_LOOP);
						push(@armAnnot, $FP_ARM_TOP3_LOOP);
						foreach my $pos (0 .. $extendLoop-1){
							push(@armAnnot, $FP_ARM_RIGHT_LOOP);
						}
					}
					else{
						my $extendLoop = ($loopLength - 3) / 2;
						foreach my $pos (0 .. $extendLoop-1){
							push(@armAnnot, $FP_ARM_LEFT_LOOP);
						}
						push(@armAnnot, $FP_ARM_TOP1_LOOP);
						push(@armAnnot, $FP_ARM_TOP2_LOOP);
						push(@armAnnot, $FP_ARM_TOP3_LOOP);
						foreach my $pos (0 .. $extendLoop-1){
							push(@armAnnot, $FP_ARM_RIGHT_LOOP);
						}
					}
				}
			
				#simultaneously walk left and right from the arm loop
				my $leftAdj = 0;
				my $rightAdj = 0;
				for(my $armloopDistance = 1; 1 == 1; $armloopDistance++){
					my $leftStr;
					my $rightStr;
					my $leftDist = $loopLeft + 1 - ($armloopDistance - $leftAdj);
					my $rightDist = $loopRight - 1 + $armloopDistance - $rightAdj;
					if($leftDist < $armEnd){
						$leftStr = "";
					}
					else{
						$leftStr = $structure[$leftDist];
					}
					if($rightDist > $armStart){
						$rightStr = "";
					}
					else{
						$rightStr = $structure[$rightDist];
					}
				
					if(!$leftStr && !$rightStr){
						last;
					}
				
					#( with )
					if($leftStr eq "(" && $rightStr eq ")"){
						unshift(@armAnnot, $FP_ARM_LEFT_BASEPAIR);
						push(@armAnnot, $FP_ARM_RIGHT_BASEPAIR);
					}
				
					#. with .
					elsif($leftStr eq "." && $rightStr eq "."){
						unshift(@armAnnot, $FP_ARM_LEFT_UNPAIRED);
						push(@armAnnot, $FP_ARM_RIGHT_UNPAIRED);
					}
				
					#( with .
					elsif($leftStr eq "(" && $rightStr eq "."){
						unshift(@armAnnot, $FP_ARM_LEFT_GAP);
						push(@armAnnot, $FP_ARM_RIGHT_UNPAIRED);
						$leftAdj++;
					}
				
					#. with )
					elsif($leftStr eq "." && $rightStr eq ")"){
						unshift(@armAnnot, $FP_ARM_LEFT_UNPAIRED);
						push(@armAnnot, $FP_ARM_RIGHT_GAP);
						$rightAdj++;
					}
				}
				foreach my $a (@armAnnot){
					unshift(@annotation, $a);
				}
				$leftArm += scalar(@armAnnot);
				$rightAdjust++;
				$tpArmFill += 3;
			}
		
			#arm: $right = (
			elsif($rightSymbol eq "("){
				my $armStart = $rightDistance;	#position of first ( in 3' arm
				my $armEnd;						#position of last ) in 3' arm
				my $armOpen = 0;				#number of )
				my $armClose = 0;				#number of (
				my $closeReached = 0;			#end of arm loop has been seen
				my $loopLeft;					#position of first ( left of arm loop
				my $loopRight;					#position of first ) right of arm loop
				my @armAnnot;
			
				#walk right across the arm to determine its length
				for(my $index = $armStart; 1 == 1; $index++){
					if(!$closeReached){
						if($structure[$index] eq "("){
							$armOpen++;
						}
						elsif($structure[$index] eq ")"){
							$closeReached = 1;
							$armClose++;
							$loopRight = $index;
							my $loop = 1;
							my $loopSize = 0;
							while($structure[$index-$loop] eq "."){
								$loop++;
								$loopSize++;
							}
							$loopLeft = $index - $loopSize - 1;
						}
					}
					else{
						if($armOpen == $armClose){
							$armEnd = $index - 1;
							last;
						}
						elsif($structure[$index] eq ")"){
							$armClose++;
						}
					}
				}
			
				#annotate arm loop
				my $loopLength = $loopRight - $loopLeft - 1;
				if($loopLength == 1){
					push(@armAnnot, $TP_ARM_BOTTOM2_LOOP);
				}
				elsif($loopLength == 2){
					push(@armAnnot, $TP_ARM_BOTTOM1_LOOP);
					push(@armAnnot, $TP_ARM_BOTTOM3_LOOP);
				}
				elsif($loopLength == 3){
					push(@armAnnot, $TP_ARM_RIGHT_LOOP);
					push(@armAnnot, $TP_ARM_BOTTOM2_LOOP);
					push(@armAnnot, $TP_ARM_LEFT_LOOP);
				}
				elsif($loopLength == 4){
					push(@armAnnot, $TP_ARM_RIGHT_LOOP);
					push(@armAnnot, $TP_ARM_BOTTOM1_LOOP);
					push(@armAnnot, $TP_ARM_BOTTOM3_LOOP);
					push(@armAnnot, $TP_ARM_LEFT_LOOP);
				}
				elsif($loopLength >= 5){
					if($loopLength % 2 == 0){
						my $extendLoop = ($loopLength - 2) / 2;
						foreach my $pos (0 .. $extendLoop-1){
							push(@armAnnot, $TP_ARM_RIGHT_LOOP);
						}
						push(@armAnnot, $TP_ARM_BOTTOM1_LOOP);
						push(@armAnnot, $TP_ARM_BOTTOM3_LOOP);
						foreach my $pos (0 .. $extendLoop-1){
							push(@armAnnot, $TP_ARM_LEFT_LOOP);
						}
					}
					else{
						my $extendLoop = ($loopLength - 3) / 2;
						foreach my $pos (0 .. $extendLoop-1){
							push(@armAnnot, $TP_ARM_RIGHT_LOOP);
						}
						push(@armAnnot, $TP_ARM_BOTTOM1_LOOP);
						push(@armAnnot, $TP_ARM_BOTTOM2_LOOP);
						push(@armAnnot, $TP_ARM_BOTTOM3_LOOP);
						foreach my $pos (0 .. $extendLoop-1){
							push(@armAnnot, $TP_ARM_LEFT_LOOP);
						}
					}
				}
			
				#simultaneously walk left and right from the arm loop
				my $leftAdj = 0;
				my $rightAdj = 0;
				for(my $armloopDistance = 1; 1 == 1; $armloopDistance++){
					my $leftStr;
					my $rightStr;
					my $leftDist = $loopLeft + 1 - ($armloopDistance - $leftAdj);
					my $rightDist = $loopRight - 1 + $armloopDistance - $rightAdj;
					if($leftDist < $armStart){
						$leftStr = "";
					}
					else{
						$leftStr = $structure[$leftDist];
					}
					if($rightDist > $armEnd){
						$rightStr = "";
					}
					else{
						$rightStr = $structure[$rightDist];
					}
					if(!$leftStr && !$rightStr){
						last;
					}
				
					#( with )
					if($leftStr eq "(" && $rightStr eq ")"){
						unshift(@armAnnot, $TP_ARM_RIGHT_BASEPAIR);
						push(@armAnnot, $TP_ARM_LEFT_BASEPAIR);
					}
				
					#. with .
					elsif($leftStr eq "." && $rightStr eq "."){
						unshift(@armAnnot, $TP_ARM_RIGHT_UNPAIRED);
						push(@armAnnot, $TP_ARM_LEFT_UNPAIRED);
					}
				
					#( with .
					elsif($leftStr eq "(" && $rightStr eq "."){
						unshift(@armAnnot, $TP_ARM_RIGHT_GAP);
						push(@armAnnot, $TP_ARM_LEFT_UNPAIRED);
						$leftAdj++;
					}
				
					#. with )
					elsif($leftStr eq "." && $rightStr eq ")"){
						unshift(@armAnnot, $TP_ARM_RIGHT_UNPAIRED);
						push(@armAnnot, $TP_ARM_LEFT_GAP);
						$rightAdj++;
					}
				}
				foreach my $a (@armAnnot){
					push(@annotation, $a);
				}
				$rightArm += scalar(@armAnnot);
				$leftAdjust++;
				$fpArmFill += 3;
			}
		}
	
		#use annotation to draw 2D character plot of RNA structure
		my $row = 50;
		my $col = 5;
		my @structPlot;
		my $state = "stem";
		my $prime = "five";
		foreach my $annot (@annotation){
	
			#Change state
			if($state eq "stem" && $annot =~ m/fp_arm_left/){
				$state = "fp_arm_left";
				$row--;
			}
			elsif($state eq "fp_arm_left" && $annot =~ m/fp_arm_right/){
				$state = "fp_arm_right";
				$col += 2;
				$row++;
			}
			elsif($state eq "fp_arm_right" && $annot =~ m/fp_stem|hairpin/){
				$state = "stem";
				$col++;
			}
			elsif($state eq "stem" && $annot =~ m/tp_arm_right/){
				$state = "tp_arm_right";
				$row++;
			}
			elsif($state eq "tp_arm_right" && $annot =~ m/tp_arm_left/){
				$state = "tp_arm_left";
				$col -= 2;
				$row--;
			}
			elsif($state eq "tp_arm_left" && $annot =~ m/tp_stem/){
				$state = "stem";
				$col--;
			}
			if($prime eq "five" && $annot =~ m/tp_stem/){
				$row += 2;
				$col--;
				$prime = "three";
			}
		
			#
			# FP STEM
			#
		
			#move right
			if($annot eq $FP_STEM_BASEPAIR){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col] = $nuc;
				$structPlot[$row+1][$col] = "|";
				$col++;
			}
		
			#move right
			elsif($annot eq $FP_STEM_UNPAIRED){
				my $nuc = shift(@sequence);
				$structPlot[$row-1][$col] = $nuc;
				$col++;
			}
		
			#move right
			elsif($annot eq $FP_STEM_GAP){
				$structPlot[$row-1][$col] = "-";
				$col++;
			}
		
			#
			# FP ARM
			#
		
			#move up
			elsif($annot eq $FP_ARM_LEFT_BASEPAIR){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col] = $nuc;
				$structPlot[$row][$col+1] = "-";
				$row--;
			}
		
			#move up
			elsif($annot eq $FP_ARM_LEFT_UNPAIRED){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col-1] = $nuc;
				$row--;
			}
		
			#move up
			elsif($annot eq $FP_ARM_LEFT_GAP){
				$structPlot[$row][$col-1] = "|";
				$row--;
			}
		
			#move up
			elsif($annot eq $FP_ARM_LEFT_LOOP){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col-1] = $nuc;
				$row--;
			}
		
			#do not move
			elsif($annot eq $FP_ARM_TOP1_LOOP){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col] = $nuc;
			}
		
			#do not move
			elsif($annot eq $FP_ARM_TOP2_LOOP){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col+1] = $nuc;
			}
		
			#do not move
			elsif($annot eq $FP_ARM_TOP3_LOOP){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col+2] = $nuc;
			}
		
			#move down
			elsif($annot eq $FP_ARM_RIGHT_LOOP){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col+1] = $nuc;
				$row++;
			}
		
			#move down
			elsif($annot eq $FP_ARM_RIGHT_BASEPAIR){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col] = $nuc;
				$row++;
			}
			
			#move down
			elsif($annot eq $FP_ARM_RIGHT_UNPAIRED){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col+1] = $nuc;
				$row++;
			}
		
			#move down
			elsif($annot eq $FP_ARM_RIGHT_GAP){
				$structPlot[$row][$col+1] = "-";
				$row++;
			}
		
			#
			# HAIRPIN
			#
		
			#move right
			elsif($annot eq $HAIRPIN_LOOP_TOP){
				my $nuc = shift(@sequence);
				$structPlot[$row-1][$col] = $nuc;
				$col++;
			}
		
			#do not move
			elsif($annot eq $HAIRPIN_LOOP_SIDE1){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col] = $nuc;
			}
		
			#do not move
			elsif($annot eq $HAIRPIN_LOOP_SIDE2){
				my $nuc = shift(@sequence);
				$structPlot[$row+1][$col] = $nuc;
			}
		
			#do not move
			elsif($annot eq $HAIRPIN_LOOP_SIDE3){
				my $nuc = shift(@sequence);
				$structPlot[$row+2][$col] = $nuc;
			}
		
			#move left
			elsif($annot eq $HAIRPIN_LOOP_BOTTOM){
				my $nuc = shift(@sequence);
				$structPlot[$row+3][$col-1] = $nuc;
				$col--;
			}
		
			#
			# TP STEM
			#
		
			#move left
			elsif($annot eq $TP_STEM_BASEPAIR){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col] = $nuc;
				$col--;
			}
		
			#move left
			elsif($annot eq $TP_STEM_UNPAIRED){
				my $nuc = shift(@sequence);
				$structPlot[$row+1][$col] = $nuc;
				$col--;
			}
		
			#move left
			elsif($annot eq $TP_STEM_GAP){
				$structPlot[$row+1][$col] = "-";
				$col--;
			}
		
			#
			# TP ARM
			#
		
			#move down
			elsif($annot eq $TP_ARM_RIGHT_BASEPAIR){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col] = $nuc;
				$structPlot[$row][$col-1] = "-";
				$row++;
			}
		
			#move down
			elsif($annot eq $TP_ARM_RIGHT_UNPAIRED){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col+1] = $nuc;
				$row++;
			}
		
			#move down
			elsif($annot eq $TP_ARM_RIGHT_GAP){
				$structPlot[$row][$col+1] = "|";
				$row++;
			}
		
			#move down
			elsif($annot eq $TP_ARM_RIGHT_LOOP){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col+1] = $nuc;
				$row++;
			}
		
			#do not move
			elsif($annot eq $TP_ARM_BOTTOM1_LOOP){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col] = $nuc;
			}
		
			#do not move
			elsif($annot eq $TP_ARM_BOTTOM2_LOOP){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col-1] = $nuc;
			}
		
			#do not move
			elsif($annot eq $TP_ARM_BOTTOM3_LOOP){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col-2] = $nuc;
			}
		
			#move down
			elsif($annot eq $TP_ARM_LEFT_LOOP){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col-1] = $nuc;
				$row--;
			}
		
			#move down
			elsif($annot eq $TP_ARM_LEFT_BASEPAIR){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col] = $nuc;
				$row--;
			}
		
			#move down
			elsif($annot eq $TP_ARM_LEFT_UNPAIRED){
				my $nuc = shift(@sequence);
				$structPlot[$row][$col-1] = $nuc;
				$row--;
			}
		
			#move down
			elsif($annot eq $TP_ARM_LEFT_GAP){
				$structPlot[$row][$col-1] = "|";
				$row--;
			}
		}
	
		#Find bounding box around structure plot
		my $leftSide;
		my $topSide;
		my $rightSide;
		my $bottomSide;
		my $found = 0;
	
		#top side
		for(my $row = 0; $row <= 100; $row++){
			for(my $col = 0; $col <= 100; $col++){
				if($structPlot[$row][$col]){
					$topSide = $row;
					$found = 1;
					last;
				}
			}
			if($found){
				last;
			}
		}
	
		#left side
		$found = 0;
		for(my $col = 0; $col <= 100; $col++){
			for(my $row = 0; $row <= 100; $row++){
				if($structPlot[$row][$col]){
					$leftSide = $col;
					$found = 1;
					last;
				}
			}
			if($found){
				last;
			}
		}
	
		#right side
		$found = 0;
		for(my $col = 200; $col > 0; $col--){
			for(my $row = 0; $row <= 100; $row++){
				if($structPlot[$row][$col]){
					$rightSide = $col;
					$found = 1;
					last;
				}
			}
			if($found){
				last;
			}
		}
	
		#bottom side
		$found = 0;
		for(my $row = 200; $row > 0; $row--){
			for(my $col = 0; $col <= 100; $col++){
				if($structPlot[$row][$col]){
					$bottomSide = $row;
					$found = 1;
					last;
				}
			}
			if($found){
				last;
			}
		}
	
		#print plot to output file
		for(my $row = $topSide; $row < $bottomSide + 1; $row++){
			for(my $col = $leftSide - 3; $col < $rightSide + 3; $col++){
				if($structPlot[$row][$col]){
					print(OUTPUT $structPlot[$row][$col]);
				}
				else{
					print(OUTPUT " ");
				}
			}
			print(OUTPUT "\n");
		}
		print(OUTPUT "\n");
	}
	close(OUTPUT);
}

return 1;

