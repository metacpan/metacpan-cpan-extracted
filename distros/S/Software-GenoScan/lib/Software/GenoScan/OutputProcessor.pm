package Software::GenoScan::OutputProcessor;

use warnings;
use strict;

require Exporter;

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	writeOutput
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

#Description: Writes miRNA candidates to output file
#Parameters: (1) probability threshold, (2) low-complexity thresshold, (3) output directory, (4) verbose flag, (5) log array
#Return value: None
sub writeOutput($ $ $ $ $){
	my ($PROBABILITY_THRESHOLD, $LOW_COMPLEXITY, $OUTPUT_DIR, $VERBOSE, $logArray) = @_;
	if(! -e $OUTPUT_DIR){
		system("mkdir $OUTPUT_DIR");
	}
	if(!-e "$OUTPUT_DIR/step_5"){
		system("mkdir $OUTPUT_DIR/step_5");
	}
	if($VERBOSE){
		print("    Filtering hairpins by low-complexity > $LOW_COMPLEXITY and probability >= $PROBABILITY_THRESHOLD\n");
	}
	push(@{$logArray}, "Step 5: write miRNA candidates to output file\n");
	
	#Read regression model report
	open(REPORT, "$OUTPUT_DIR/step_4/log_reg_model_report") or die "GenoScan error: Unable to read log_reg_model_report\n";
	my @report = <REPORT>;
	close(REPORT);
	my $numHp = scalar(@report);
	if($VERBOSE){
		print("    Total number of hairpins: $numHp\n");
	}
	push(@{$logArray}, "\tTotal number of hairpins: $numHp\n");
	
	#Filter by low-complexity and probability threshold
	open(PASS, ">$OUTPUT_DIR/step_5/miRNA_candidates.fasta");
	my $passCounter = 0;
	my $lowCompCounter = $numHp;
	foreach my $hp (@report){
		$hp =~ s/\s+$//;
		my ($header, $seq, $probability) = split(/\t/, $hp);
		my $lowComp = () = $seq =~ m/[augc]/g;
		$lowComp = $lowComp / length($seq);
		if($lowComp > $LOW_COMPLEXITY){
			$lowCompCounter--;
			next;
		}
		if($probability >= $PROBABILITY_THRESHOLD){
			$passCounter++;
			print(PASS ">$header\n$seq\n");
		}
	}
	close(PASS);
	if($VERBOSE){
		print("    Number of hairpins passing low-complexity: $lowCompCounter\n");
		print("    Number of hairpins passing threshold: $passCounter\n");
	}
	push(@{$logArray}, "\tNumber of hairpins passing low-complexity: $lowCompCounter\n");
	push(@{$logArray}, "\tNumber of hairpins passing threshold: $passCounter\n");
	
	#Write logfile
	open(LOG, ">$OUTPUT_DIR/step_5/genoscan_log") or die "Unable to write logfile\n";
	print(LOG @{$logArray});
	close(LOG);
	if($VERBOSE){
		print("    miRNA candidates written to $OUTPUT_DIR/step_5/miRNA_candidates.fasta\n");
	}
}

return 1;

