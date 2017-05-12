package Software::GenoScan;

use 5.010000;
use warnings;
use strict;
local $| = 1;

use Software::GenoScan::CommandProcessor qw(processCmd);
use Software::GenoScan::SeqAnnotator qw(readAnnotation);
use Software::GenoScan::InputProcessor qw(processInput);
use Software::GenoScan::HairpinExtractor qw(extractHairpins);
use Software::GenoScan::HairpinClassifier qw(classifyHairpins);
use Software::GenoScan::OutputProcessor qw(writeOutput);
use Software::GenoScan::Regression qw(benchmarkRegModel retrainRegModel);
require Exporter;

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	runGenoScan
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

#Default paths to R-scripts
my $benchmarkScript = "../scripts/benchmark.R";
my $retrainScript = "../scripts/retrain.R";

#Command-line arguments
my $MODE = "genome";
my $INPUT_DIR = "";
my $ANNOT_EXCLUSION_DIR = "";
my $ANNOT_INCLUSION_FILE = "";
my $PROBABILITY_THRESHOLD = 0.5;
my $HP_EXTRACTION_FILE = "";
my $POS_DATASET = "";
my $NEG_DATASET = "";
my $GEN_DATASET = "";
my $SCRIPT_PATH = "";
my $SPECIES_CODE = "hsa";
my $LOW_COMPLEXITY = 1;
my $OUTPUT_DIR = "";
my $REGRESSION = "";
my $CLASSIFY_SET = "";
my $JUMP = 1;
my $VERBOSE = 0;

#RNAfold run command
my $RNAfold = "RNAfold --noPS";

#Description: Determines environment paths of all prerequisites
#Parameters: None
#Return value: None
sub checkEnvSanity(){
	my $path = qx(which RNAfold);
	if(!$path){
		die "GenoScan error: RNAfold not found, terminating\n";
	}
	Software::GenoScan::InputProcessor::commandRNAfold($RNAfold);
	Software::GenoScan::Regression::commandRNAfold($RNAfold);
}

#Description: Wrapper function for running GenoScan
#Parameters: Command line arguments
#Return value: None
sub runGenoScan{
	my @args = @_;
	my %commands = processCmd(
		"commandline"           => \@args,
		"MODE"                  => \$MODE,
		"INPUT_DIR"             => \$INPUT_DIR,
		"ANNOT_EXCLUSION_DIR"   => \$ANNOT_EXCLUSION_DIR,
		"ANNOT_INCLUSION_FILE"  => \$ANNOT_INCLUSION_FILE,
		"PROBABILITY_THRESHOLD" => \$PROBABILITY_THRESHOLD,
		"HP_EXTRACTION_FILE"    => \$HP_EXTRACTION_FILE,
		"POS_DATASET"           => \$POS_DATASET,
		"NEG_DATASET"           => \$NEG_DATASET,
		"GEN_DATASET"           => \$GEN_DATASET,
		"SCRIPT_PATH"           => \$SCRIPT_PATH,
		"SPECIES_CODE"          => \$SPECIES_CODE,
		"LOW_COMPLEXITY"        => \$LOW_COMPLEXITY,
		"OUTPUT_DIR"            => \$OUTPUT_DIR,
		"REGRESSION"            => \$REGRESSION,
		"CLASSIFY_SET"          => \$CLASSIFY_SET,
		"JUMP"					=> \$JUMP,
		"VERBOSE"               => \$VERBOSE
	);
	checkEnvSanity();
	my @log = "GenoScan logfile\n\nParameters used:\n";
	push(@log, "\tMode: ${${$commands{'-m'}}{'var'}}\n");
	push(@log, "\tInput dir: ${${$commands{'-d'}}{'var'}}\n");
	push(@log, "\tGBS dir: ${${$commands{'-e'}}{'var'}}\n");
	push(@log, "\tInclusion filters: ${${$commands{'-i'}}{'var'}}\n");
	push(@log, "\tProbability threshold: ${${$commands{'-t'}}{'var'}}\n");
	push(@log, "\tExtraction parameters: ${${$commands{'-f'}}{'var'}}\n");
	push(@log, "\tPositive dataset: ${${$commands{'-p'}}{'var'}}\n");
	push(@log, "\tNegative dataset: ${${$commands{'-n'}}{'var'}}\n");
	push(@log, "\tGenomic dataset: ${${$commands{'-g'}}{'var'}}\n");
	push(@log, "\tSpecies: ${${$commands{'-s'}}{'var'}}\n");
	push(@log, "\tLow complexity: ${${$commands{'-l'}}{'var'}}\n");
	push(@log, "\tOutput dir: ${${$commands{'-o'}}{'var'}}\n");
	push(@log, "\tRegression parameters: ${${$commands{'-r'}}{'var'}}\n");
	push(@log, "\tClassification set: ${${$commands{'-c'}}{'var'}}\n");
	push(@log, "\tStart step: ${${$commands{'-j'}}{'var'}}\n");
	push(@log, "\tVerbose flag: ${${$commands{'-v'}}{'var'}}\n\n");
	
	#Discovery miRNAs in genomic sequences
	if($MODE eq "genome"){
		if($JUMP <= 1){
			if($VERBOSE){
				print("GenoScan step 1: read annotation filters\n");
			}
			readAnnotation($ANNOT_EXCLUSION_DIR, $ANNOT_INCLUSION_FILE, $OUTPUT_DIR, $VERBOSE, \@log);
		}
		if($JUMP <= 2){
			if($VERBOSE){
				print("GenoScan step 2: segmentize and fold input sequences\n");
			}
			processInput($INPUT_DIR, $OUTPUT_DIR, $VERBOSE, \@log);
		}
		if($JUMP <= 3){
			if($VERBOSE){
				print("GenoScan step 3: extract hairpins\n");
			}
			extractHairpins($SPECIES_CODE, $HP_EXTRACTION_FILE, $OUTPUT_DIR, $VERBOSE, \@log);
		}
		if($JUMP <= 4){
			if($VERBOSE){
				print("GenoScan step 4: classify hairpins\n");
			}
			classifyHairpins($OUTPUT_DIR, $REGRESSION, $VERBOSE, \@log);
		}
		if($JUMP <= 5){
			if($VERBOSE){
				print("GenoScan step 5: write miRNA candidates to output file\n");
			}
			writeOutput($PROBABILITY_THRESHOLD, $LOW_COMPLEXITY, $OUTPUT_DIR, $VERBOSE, \@log);
		}
		if($VERBOSE){
			print("GenoScan: job finished\n");
		}
	}
	
	#Classify extracted hairpins
	elsif($MODE eq "classify"){
		if(! -e $OUTPUT_DIR){
			system("mkdir $OUTPUT_DIR");
		}
		if(! -e "$OUTPUT_DIR/step_3"){
			system("mkdir $OUTPUT_DIR/step_3");
		}
		if(! -e $CLASSIFY_SET){
			die "GenoScan error: Unable to locate classify set '$CLASSIFY_SET'\n";
		}
		else{
			my $classifyFile = $CLASSIFY_SET;
			$classifyFile =~ m/([^\/]+)$/;
			$classifyFile = $1;
			system("cp $CLASSIFY_SET $OUTPUT_DIR/step_3/$classifyFile");
		}
		if($VERBOSE){
			print("GenoScan step 4: classify hairpins\n");
		}
		classifyHairpins($OUTPUT_DIR, $REGRESSION, $VERBOSE, \@log);
		if($VERBOSE){
			print("GenoScan step 5: write miRNA candidates to output file\n");
		}
		writeOutput($PROBABILITY_THRESHOLD, $LOW_COMPLEXITY, $OUTPUT_DIR, $VERBOSE, \@log);
	}
	
	#Benchmark on dataset
	elsif($MODE eq "benchmark"){
		if(!$SCRIPT_PATH){
			$SCRIPT_PATH = $benchmarkScript;
		}
		if($VERBOSE){
			print("GenoScan: Benchmarking regression model\n");
		}
		benchmarkRegModel($POS_DATASET, $NEG_DATASET, $GEN_DATASET, $OUTPUT_DIR, $VERBOSE, $SCRIPT_PATH, \@log);
	}
	
	#Retrain regression model on dataset
	elsif($MODE eq "retrain"){
		if(!$SCRIPT_PATH){
			$SCRIPT_PATH = $retrainScript;
		}
		if($VERBOSE){
			print("GenoScan: Retraining regression model\n");
		}
		retrainRegModel($POS_DATASET, $NEG_DATASET, $OUTPUT_DIR, $VERBOSE, $SCRIPT_PATH, \@log);
	}
}

return 1;

