package Software::GenoScan::HairpinClassifier;

use warnings;
use strict;

use Software::GenoScan::Regression qw(calcHpFeatures getRegModel readRegModel hairpinRVA);
require Exporter;

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	classifyHairpins
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

#Description: Wrapper function for hairpin classification
#Parameters: (1) Output directory, (2) regression model file, (3) verbose flag, (4) log array
#Return value: None
sub classifyHairpins($ $ $ $){
	my ($OUTPUT_DIR, $REGRESSION, $VERBOSE, $logArray) = @_;
	if(! -e $OUTPUT_DIR){
		system("mkdir $OUTPUT_DIR");
	}
	if(!-e "$OUTPUT_DIR/step_4"){
		system("mkdir $OUTPUT_DIR/step_4");
	}
	if(!-e "$OUTPUT_DIR/step_4/folded"){
		system("mkdir $OUTPUT_DIR/step_4/folded");
	}
	if(!-e "$OUTPUT_DIR/step_4/visual"){
		system("mkdir $OUTPUT_DIR/step_4/visual");
	}
	if(!-e "$OUTPUT_DIR/step_4/annotation"){
		system("mkdir $OUTPUT_DIR/step_4/annotation");
	}
	push(@{$logArray}, "Step 4: classify hairpins\n");
	if($REGRESSION){
		readRegModel($REGRESSION);
	}
	my %coefficients = getRegModel();
	
	#Open classification report file
	open(REPORT, ">$OUTPUT_DIR/step_4/log_reg_model_report") or die "GenoScan error: Unable to write log_reg_model_report\n";
	
	#Refold, visualize and annotate
	hairpinRVA("$OUTPUT_DIR/step_3", "$OUTPUT_DIR/step_4/folded", "$OUTPUT_DIR/step_4/visual", "$OUTPUT_DIR/step_4/annotation", $VERBOSE, $logArray);
	
	#Classify chunks based on logistic regression model
	my $fileCounter = 0;
	my @files = split(/\n+/, qx(ls $OUTPUT_DIR/step_4/annotation));
	my $numFiles = scalar(@files);
	my @annotFiles = grep(/[^~]$/, @files);
	foreach my $annotFile (@annotFiles){
		$fileCounter++;
		if($VERBOSE){
			print("    Classifying chunk $fileCounter/$numFiles\r");
		}
		
		#Read annotated chunk
		open(HAIRPINS, "$OUTPUT_DIR/step_4/annotation/$annotFile") or die "GenoScan error: Unable to read annotation file\n";
		my @hairpins = split(/>/, join("", <HAIRPINS>));
		shift(@hairpins);
		close(HAIRPINS);
		
		#Classify hairpins
		foreach my $hp (@hairpins){
			my ($header, $visual, $annot) = split(/\n\n/, $hp);
			my ($name, $seq, $sec) = split(/\n/, $header);
			my %features = calcHpFeatures($hp);
			my @covars = keys(%features);
	
			#Classification
			my $probability = $coefficients{"(Intercept)"};
			foreach my $covar (@covars){
				$probability += $coefficients{$covar} * $features{$covar};
			}
			$probability = exp($probability) / (1 + exp($probability));
			print(REPORT "$name\t$seq\t$probability\n");
		}
	}
	if($VERBOSE){
		print("\n");
	}
	close(REPORT);
}

return 1;

