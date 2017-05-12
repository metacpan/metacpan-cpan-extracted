package Software::GenoScan::Regression;

use 5.010000;
use warnings;
use strict;

use Software::GenoScan::FoldVisualizer qw(visualizeFold);
use Software::GenoScan::HSS_Annotator qw(annotateHSS);

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	calcHpFeatures getRegModel readRegModel hairpinRVA benchmarkRegModel retrainRegModel
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

#RNAfold command
my $RNAfold;

#Regression model coefficients
my %coefficients = (
	"(Intercept)"   => 10.5280777518279,
	"stem_len"      => 0.0500355477383941,
	"loop_size"     => 0.320050551436161,
	"mfe_nor"       => -6.61410292089138,
	"prop_gap"      => -17.1624469004961,
	"prop_bulge"    => 4.80460097209541,
	"prop_wobble"   => -3.18891064122477,
	"gc_content"    => -8.89487058546057,
	"PPP"           => -4.61085343984701,
	"UUU"           => -9.76065756139253,
	"UUP"           => -26.0725578749436,
	"PPU"           => -27.0092130076774,
	"PUP"           => -11.7589439172359,
	"UPP"           => 23.1858571677642
);

#Description: Calculates hairpin values for sequence and structure features
#Parameters: Annotated hairpin
#Return value: Feature hash
sub calcHpFeatures($){
	my $hp = shift(@_);
	my ($header, $visual, $annot) = split(/\n\n/, $hp);
	my ($name, $seq, $sec) = split(/\n/, $header);
	$name = ">$name";
	my ($fp1, $fp2, $middle, $tp2, $tp1) = split(/\n/, $visual);
	my ($region, $ssn) = split(/\n/, $annot);
	my @fp1 = split("", $fp1);
	my @fp2 = split("", $fp2);
	my @tp2 = split("", $tp2);
	my @tp1 = split("", $tp1);
	my @region = split("", $region);
	my @ssn = split("", $ssn);
	my @seq = split("", $seq);

	#Stem length
	my $stemLen = () = $region =~ m/S/g;

	#Loop size and MFE
	my ($str, $value, $dummy) = split(/\s/, $sec);
	my @sec = split("", $str);
	if($dummy){
		$value .= $dummy;
	}
	$str =~ m/\((\.+)\)/;
	my $loopSize = length($1);
	$value =~ m/(-?[0-9]+(\.[0-9]+)?)/;
	my $mfe = $1;
	my $mfeNor = $mfe / $stemLen;

	#Proportion of S, A, gap, B and GC in stem
	my $propSym = 0;
	my $propAsym = 0;
	my $propGap = 0;
	my $propBulge = 0;
	my $propWobble = 0;
	my $gcContent = 0;
	foreach my $pos (0..scalar(@region)-1){
		if($region[$pos] ne "S"){
			next;
		}
		if($ssn[$pos] eq "S"){
			$propSym++;
		}
		elsif($ssn[$pos] eq "A"){
			$propAsym++;
		}
		elsif($ssn[$pos] eq "W"){
			$propWobble++;
		}
		elsif($ssn[$pos] eq "B"){
			$propBulge++;
		}
		if($fp1[$pos] eq "-"){
			$propGap++;
		}
		if($tp1[$pos] eq "-"){
			$propGap++;
		}
		if($fp1[$pos] eq "G" || $fp1[$pos] eq "C" || $fp2[$pos] eq "G" || $fp2[$pos] eq "C"){
			$gcContent++;
		}
		if($tp1[$pos] eq "G" || $tp1[$pos] eq "C" || $tp2[$pos] eq "G" || $tp2[$pos] eq "C"){
			$gcContent++;
		}
	}
	$propSym /= $stemLen;
	$propAsym /= $stemLen;
	$propGap /= $stemLen;
	$propBulge /= $stemLen;
	$propWobble /= $stemLen;
	$gcContent /= $stemLen * 2;

	#Structure triplets
	my %tripletFreq;
	foreach my $triplet ("(((", "...", "(..", ".(.", "..(", "((.", "(.(", ".(("){
		$tripletFreq{$triplet} = 0;
	}
	foreach my $pos (0 .. scalar(@sec)-3){
		my $triplet = $sec[$pos] . $sec[$pos+1] . $sec[$pos+2];
		$triplet =~ s/\)/(/g;
		$tripletFreq{$triplet}++;
	}
	foreach my $triplet ("(((", "...", "(..", ".(.", "..(", "((.", "(.(", ".(("){
		$tripletFreq{$triplet} /= $stemLen;
	}

	#Build feature hash
	my %features = (
		"stem_len"		=> $stemLen,
		"loop_size"		=> $loopSize,
		"mfe_nor"		=> $mfeNor,
		"prop_gap"		=> $propGap,
		"prop_bulge"	=> $propBulge,
		"prop_wobble"	=> $propWobble,
		"gc_content"	=> $gcContent,
		"PPP"			=> $tripletFreq{"((("},
		"UUU"			=> $tripletFreq{"..."},
		"UUP"			=> $tripletFreq{"..("},
		"PPU"			=> $tripletFreq{"((."},
		"PUP"			=> $tripletFreq{"(.("},
		"UPP"			=> $tripletFreq{".(("}
	);
	return %features;
}

#Description: Sets the RNAfold running command
#Parameters: (1) RNAfold command
#Return value: None
sub commandRNAfold($){
	$RNAfold = shift(@_);
}

#Description: Returns the coefficients of the regression model
#Parameters: None
#Return value: Coeffifients hash
sub getRegModel(){
	return %coefficients;
}

#Description: Reads a file with custom regression model coefficients
#Parameters: Regression model file
#Return value: None
sub readRegModel($){
	my $regFile = shift(@_);
	open(MODEL, "$regFile") or die "GenoScan error: Unable to read regression model file\n";
	my $classModel = join("", <MODEL>);
	$classModel =~ s/\r|\r\n|\n\r/\n/g;
	my @classModel = split(/\n+/, $classModel);
	close(MODEL);
	foreach my $row (@classModel){
		my ($covar, $coef) = split(/\t/, $row);
		$coefficients{$covar} = $coef;
	}
}

#Description: Wrapper function for refolding, visualizing and annotating hairpins
#Parameters: (1) folder with hiaprins to process, (2) output folder for folds,
#            (3) output folder for visuals and (4) output folder for annotation
#            (5) verbose flag, (6) log array
#Return value: None
sub hairpinRVA($ $ $ $ $ $){
	my ($hairpinFolder, $foldedFolder, $visualFolder, $annotationFolder, $VERBOSE, $logArray) = @_;
	
	#Detect hairpin files
	my @files = split(/\n+/, qx(ls $hairpinFolder));
	my @extractedFiles = grep(/[^~]$/, @files);
	my $numFiles = scalar(@extractedFiles);
	if($VERBOSE){
		print("    $numFiles hairpin files found\n");
	}
	if($numFiles == 0){
		die "GenoScan: No hairpin files, terminating\n";
	}
	push(@{$logArray}, "\t$numFiles hairpin files found\n");

	#Refold hairpin files
	my $fileCounter = 0;
	my $stlCounter = 0;
	foreach my $extFile (@extractedFiles){
		$fileCounter++;
		if($VERBOSE){
			print("    Folding file $fileCounter/$numFiles\r");
		}
		
		#Read chunk file
		open(EXT, "$hairpinFolder/$extFile") or die "GenoScan error: Unable to read hairpin file\n";
		my @hairpins = split(/>/, join("", <EXT>));
		shift(@hairpins);
		
		#Filter out hairpins that have more/less than one hairpin terminal loop
		my @stlFolded;
		foreach my $hairpin (@hairpins){
			my ($header, $seq) = split(/\n/, $hairpin);
			$header = ">$header";
			my $result = qx(echo '$seq' | $RNAfold);
			my ($foldSeq, $str) = split(/\n/, $result);
			my @loops = $str =~ m/\(\.+\)/g;
			if(scalar(@loops) == 1){
				push(@stlFolded, "$header\n$seq\n$str\n");
				$stlCounter++;
			}
		}
		my $stlFile = $extFile;
		$stlFile =~ s/\.fasta$/.folded/;
		open(STL, ">$foldedFolder/$stlFile") or die "GenoScan error: Unable to write STL file\n";
		print(STL join("\n", @stlFolded) . "\n");
		close(STL);
	}
	if($VERBOSE){
		print("\n    Number of STL hairpins: $stlCounter\n");
	}
	if($stlCounter == 0){
		die "GenoScan: No STL hairpins, terminating\n";
	}
	push(@{$logArray}, "\tNumber of STL hairpins: $stlCounter\n\n");
	
	#Visualize chunks
	$fileCounter = 0;
	@files = split(/\n+/, qx(ls $foldedFolder));
	my @foldedFiles = grep(/[^~]$/, @files);
	foreach my $foldFile (@foldedFiles){
		$fileCounter++;
		if($VERBOSE){
			print("    Visualizing file $fileCounter/$numFiles\r");
		}
		my $visualFile = $foldFile;
		$visualFile =~ s/\.folded/.visual/;
		visualizeFold("$foldedFolder/$foldFile", "$visualFolder/$visualFile");
	}
	if($VERBOSE){
		print("\n");
	}
	
	#Annotate chunks
	$fileCounter = 0;
	@files = split(/\n+/, qx(ls $visualFolder));
	my @visualFiles = grep(/[^~]$/, @files);
	foreach my $visualFile (@visualFiles){
		$fileCounter++;
		if($VERBOSE){
			print("    Annotating file $fileCounter/$numFiles\r");
		}
		my $annotFile = $visualFile;
		$annotFile =~ s/\.visual/.annotation/;
		annotateHSS("$visualFolder/$visualFile", "$annotationFolder/$annotFile");
	}
	if($VERBOSE){
		print("\n");
	}
}

#Description: Internal function used to write R-script datasets
#Parameters: (1) Annotated hairpin file, (2) output folder and (3) dataset class label
#Return value: None
sub writeRegDataset($ $ $){
	my ($datasetFile, $outputFolder, $classLabel) = (@_);
	
	#Read dataset
	open(HAIRPINS, $datasetFile) or die "GenoScan error: Unable to read dataset '$datasetFile'\n";
	my $hp = join("", <HAIRPINS>);
	close(HAIRPINS);
	my @hairpins = split(/>/, $hp);
	shift(@hairpins);
	my $numHp = scalar(@hairpins);
	
	#Write dataset
	my @covars = qw(stem_len loop_size mfe_nor prop_gap prop_bulge prop_wobble gc_content PPP UUU UUP PPU PUP UPP);
	my @dataset = ("MIRNA\t" . join("\t", @covars));
	foreach my $hp (@hairpins){
		my ($header, $visual, $annot) = split(/\n\n/, $hp);
		my ($name, $seq, $sec) = split(/\n/, $header);
		my %features = calcHpFeatures($hp);
		my @row = ($name, $classLabel);
		foreach my $covar (@covars){
			push(@row, $features{$covar});
		}
		push(@dataset, join("\t", @row));
	}
	my $outputFile = $datasetFile;
	$outputFile =~ m/([^\/]+)$/;
	$outputFile = $1;
	open(DATASET, ">$outputFolder/$outputFile.data") or die "GenoScan error: Unable to write R dataset\n";
	print(DATASET join("\n", @dataset));
	close(DATASET);
}

#Description: Benchmarks the regression model by leave-one-out cross validation
#Parameters: (1) Positive dataset, (2) negative dataset and (3) genomic dataset, (4) output directory,
#            (5) verbose flag, (6) script path, (7) log array
#Return value: None
sub benchmarkRegModel($ $ $ $ $ $ $){
	my ($POS_DATASET, $NEG_DATASET, $GEN_DATASET, $OUTPUT_DIR, $VERBOSE, $SCRIPT_PATH, $logArray) = @_;
	if(!-e "$OUTPUT_DIR"){
		system("mkdir $OUTPUT_DIR");
	}
	if(!-e "$OUTPUT_DIR/benchmark"){
		system("mkdir $OUTPUT_DIR/benchmark");
	}
	if(!-e "$OUTPUT_DIR/benchmark/folded"){
		system("mkdir $OUTPUT_DIR/benchmark/folded");
	}
	if(!-e "$OUTPUT_DIR/benchmark/visual"){
		system("mkdir $OUTPUT_DIR/benchmark/visual");
	}
	if(!-e "$OUTPUT_DIR/benchmark/annotation"){
		system("mkdir $OUTPUT_DIR/benchmark/annotation");
	}
	if(!-e "$OUTPUT_DIR/benchmark/fasta"){
		system("mkdir $OUTPUT_DIR/benchmark/fasta");
	}
	if(!-e "$OUTPUT_DIR/benchmark/datasets"){
		system("mkdir $OUTPUT_DIR/benchmark/datasets");
	}
	push(@{$logArray}, "Benchmarking regression model\n");
	
	#Copy input datasets to fasta folder
	if(! -e $POS_DATASET){
		die "GenoScan error: Unable to locate '$POS_DATASET'\n";
	}
	else{
		my $targetFile = $POS_DATASET;
		$targetFile =~ m/([^\/]+)$/;
		$targetFile = $1;
		system("cp $POS_DATASET $OUTPUT_DIR/benchmark/fasta/$targetFile");
		$POS_DATASET = $targetFile;
	}
	if(! -e $NEG_DATASET){
		die "GenoScan error: Unable to locate '$NEG_DATASET'\n";
	}
	else{
		my $targetFile = $NEG_DATASET;
		$targetFile =~ m/([^\/]+)$/;
		$targetFile = $1;
		system("cp $NEG_DATASET $OUTPUT_DIR/benchmark/fasta/$targetFile");
		$NEG_DATASET = $targetFile;
	}
	if(! -e $GEN_DATASET){
		die "GenoScan error: Unable to locate '$GEN_DATASET'\n";
	}
	else{
		my $targetFile = $GEN_DATASET;
		$targetFile =~ m/([^\/]+)$/;
		$targetFile = $1;
		system("cp $GEN_DATASET $OUTPUT_DIR/benchmark/fasta/$targetFile");
		$GEN_DATASET = $targetFile;
	}
	if($POS_DATASET !~ m/\.fasta$/){
		my $POS_DATASET_NEW .= "$POS_DATASET.fasta";
		system("mv $OUTPUT_DIR/benchmark/fasta/$POS_DATASET $OUTPUT_DIR/benchmark/fasta/$POS_DATASET_NEW");
		$POS_DATASET = $POS_DATASET_NEW;
	}
	if($NEG_DATASET !~ m/\.fasta$/){
		my $NEG_DATASET_NEW .= "$NEG_DATASET.fasta";
		system("mv $OUTPUT_DIR/benchmark/fasta/$NEG_DATASET $OUTPUT_DIR/benchmark/fasta/$NEG_DATASET_NEW");
		$NEG_DATASET = $NEG_DATASET_NEW;
	}
	if($GEN_DATASET !~ m/\.fasta$/){
		my $GEN_DATASET_NEW .= "$GEN_DATASET.fasta";
		system("mv $OUTPUT_DIR/benchmark/fasta/$GEN_DATASET $OUTPUT_DIR/benchmark/fasta/$GEN_DATASET_NEW");
		$GEN_DATASET = $GEN_DATASET_NEW;
	}
	
	#Fold, visualize and annotate datasets
	hairpinRVA("$OUTPUT_DIR/benchmark/fasta", "$OUTPUT_DIR/benchmark/folded", "$OUTPUT_DIR/benchmark/visual", "$OUTPUT_DIR/benchmark/annotation", $VERBOSE, $logArray);
	
	#Write R-script datasets
	if($VERBOSE){
		print("    Writing R datasets\n");
	}
	$POS_DATASET =~ s/\.fasta/.annotation/;
	$NEG_DATASET =~ s/\.fasta/.annotation/;
	$GEN_DATASET =~ s/\.fasta/.annotation/;
	writeRegDataset("$OUTPUT_DIR/benchmark/annotation/$POS_DATASET", "$OUTPUT_DIR/benchmark/datasets", 1);
	writeRegDataset("$OUTPUT_DIR/benchmark/annotation/$NEG_DATASET", "$OUTPUT_DIR/benchmark/datasets", 0);
	writeRegDataset("$OUTPUT_DIR/benchmark/annotation/$GEN_DATASET", "$OUTPUT_DIR/benchmark/datasets", 1);
	
	#Run R benchmark script
	if($VERBOSE){
		print("    Running R benchmark script\n");
	}
	$POS_DATASET .= ".data";
	$NEG_DATASET .= ".data";
	$GEN_DATASET .= ".data";
	system("Rscript $SCRIPT_PATH $OUTPUT_DIR/benchmark/datasets/$POS_DATASET $OUTPUT_DIR/benchmark/datasets/$NEG_DATASET $OUTPUT_DIR/benchmark/datasets/$GEN_DATASET");
	system("mv performance_matrix $OUTPUT_DIR/benchmark/performance_matrix");
	
	#Write logfile
	open(LOG, ">$OUTPUT_DIR/benchmark/genoscan_log") or die "Unable to write logfile\n";
	print(LOG @{$logArray});
	close(LOG);
	if($VERBOSE){
		print("    Performance matrix written to $OUTPUT_DIR/benchmark/performance_matrix\n");
	}
}

#Description: Retrains the regression model on custom datasets
#Parameters: (1) Positive dataset and (2) negative dataset, (3) output directory,
#            (4) verbose flag, (5) script path, (6) log array
#Return value: None
sub retrainRegModel($ $ $ $ $ $){
	my ($POS_DATASET, $NEG_DATASET, $OUTPUT_DIR, $VERBOSE, $SCRIPT_PATH, $logArray) = @_;
	if(!-e "$OUTPUT_DIR"){
		system("mkdir $OUTPUT_DIR");
	}
	if(!-e "$OUTPUT_DIR/retrain"){
		system("mkdir $OUTPUT_DIR/retrain");
	}
	if(!-e "$OUTPUT_DIR/retrain/folded"){
		system("mkdir $OUTPUT_DIR/retrain/folded");
	}
	if(!-e "$OUTPUT_DIR/retrain/visual"){
		system("mkdir $OUTPUT_DIR/retrain/visual");
	}
	if(!-e "$OUTPUT_DIR/retrain/annotation"){
		system("mkdir $OUTPUT_DIR/retrain/annotation");
	}
	if(!-e "$OUTPUT_DIR/retrain/fasta"){
		system("mkdir $OUTPUT_DIR/retrain/fasta");
	}
	if(!-e "$OUTPUT_DIR/retrain/datasets"){
		system("mkdir $OUTPUT_DIR/retrain/datasets");
	}
	push(@{$logArray}, "Retraining regression model\n");
	
	#Copy input datasets to fasta folder
	if(! -e $POS_DATASET){
		die "GenoScan error: Unable to locate '$POS_DATASET'\n";
	}
	else{
		my $targetFile = $POS_DATASET;
		$targetFile =~ m/([^\/]+)$/;
		$targetFile = $1;
		system("cp $POS_DATASET $OUTPUT_DIR/retrain/fasta/$targetFile");
		$POS_DATASET = $targetFile;
	}
	if(! -e $NEG_DATASET){
		die "GenoScan error: Unable to locate '$NEG_DATASET'\n";
	}
	else{
		my $targetFile = $NEG_DATASET;
		$targetFile =~ m/([^\/]+)$/;
		$targetFile = $1;
		system("cp $NEG_DATASET $OUTPUT_DIR/retrain/fasta/$targetFile");
		$NEG_DATASET = $targetFile;
	}
	if($POS_DATASET !~ m/\.fasta$/){
		my $POS_DATASET_NEW .= "$POS_DATASET.fasta";
		system("mv $OUTPUT_DIR/retrain/fasta/$POS_DATASET $OUTPUT_DIR/retrain/fasta/$POS_DATASET_NEW");
		$POS_DATASET = $POS_DATASET_NEW;
	}
	if($NEG_DATASET !~ m/\.fasta$/){
		my $NEG_DATASET_NEW .= "$NEG_DATASET.fasta";
		system("mv $OUTPUT_DIR/retrain/fasta/$NEG_DATASET $OUTPUT_DIR/retrain/fasta/$NEG_DATASET_NEW");
		$NEG_DATASET = $NEG_DATASET_NEW;
	}
	
	#Fold, visualize and annotate datasets
	hairpinRVA("$OUTPUT_DIR/retrain/fasta", "$OUTPUT_DIR/retrain/folded", "$OUTPUT_DIR/retrain/visual", "$OUTPUT_DIR/retrain/annotation", $VERBOSE, $logArray);
	
	#Write R-script datasets
	if($VERBOSE){
		print("    Writing R datasets\n");
	}
	$POS_DATASET =~ s/\.fasta/.annotation/;
	$NEG_DATASET =~ s/\.fasta/.annotation/;
	writeRegDataset("$OUTPUT_DIR/retrain/annotation/$POS_DATASET", "$OUTPUT_DIR/retrain/datasets", 1);
	writeRegDataset("$OUTPUT_DIR/retrain/annotation/$NEG_DATASET", "$OUTPUT_DIR/retrain/datasets", 0);
	
	#Run R retrain script
	if($VERBOSE){
		print("    Running R retrain script\n");
	}
	$POS_DATASET .= ".data";
	$NEG_DATASET .= ".data";
	system("Rscript $SCRIPT_PATH $OUTPUT_DIR/retrain/datasets/$POS_DATASET $OUTPUT_DIR/retrain/datasets/$NEG_DATASET");
	system("mv regression_model $OUTPUT_DIR/retrain/regression_model");
	
	#Write logfile
	open(LOG, ">$OUTPUT_DIR/retrain/genoscan_log") or die "Unable to write logfile\n";
	print(LOG @{$logArray});
	close(LOG);
	if($VERBOSE){
		print("    Regression model written to $OUTPUT_DIR/retrain/regression_model\n");
	}
}
