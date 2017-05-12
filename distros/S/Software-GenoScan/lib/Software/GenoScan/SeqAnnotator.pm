package Software::GenoScan::SeqAnnotator;

use warnings;
use strict;

require Exporter;

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	readAnnotation
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

#Description: Wrapper function for processing exclusion and inclusion annotation
#Parameters: (1) directory containing GBS annotation files, (2) file containing inclusion filters, (3) output directory, (4) verbose flag, (5) log array
#Return value: None
sub readAnnotation($ $ $ $ $){
	my ($exclusionDir, $inclusionFile, $OUTPUT_DIR, $VERBOSE, $logArray) = @_;
	if(! -e $OUTPUT_DIR){
		system("mkdir $OUTPUT_DIR");
	}
	if(! -e "$OUTPUT_DIR/step_1"){
		system("mkdir $OUTPUT_DIR/step_1");
	}
	push(@{$logArray}, "Step 1: read annotation filters\n");
	my $annotationDir = "$OUTPUT_DIR/step_1";
	my $exc = 0;
	my $inc = 0;
	if($exclusionDir){
		$exc = readGBS($exclusionDir, $annotationDir, $VERBOSE);
		push(@{$logArray}, "\tExclusion filters used\n");
	}
	if($inclusionFile){
		$inc = readIncFile($inclusionFile, $annotationDir, $VERBOSE);
		push(@{$logArray}, "\tInclusions filters used\n");
	}
	if($VERBOSE && !$exc && !$inc){
		print("    No filters supplied\n");
	}
	if(!$exc && !$inc){
		push(@{$logArray}, "\tNo filters supplied\n");
	}
	push(@{$logArray}, "\n");
}

#Description: Reads GBS files in directory and extracts exclusion filters
#Parameters: (1) directory containing GBS annotation files, (2) annotation output folder, (3) verbose flag
#Return value: 1 if annotation is extracted, 0 otherwise
sub readGBS($ $ $){
	my ($exclusionDir, $annotationDir, $VERBOSE) = @_;
	
	#Detect GBS files
	if(! -e $exclusionDir){
		die "GenoScan error: Unable to find GBS annotation directory '$exclusionDir'\n";
	}
	my @files = split(/\s+/, qx(ls $exclusionDir));
	my @gbs = grep(/gbs$/i, @files);
	my $numFiles = scalar(@gbs);
	if($VERBOSE){
		print("    $numFiles GBS file(s) found\n");
	}
	my $fileCounter = 0;
	
	#Process GBS files
	my @annotArray;
	foreach my $gbs (@gbs){
		my @gbsArray;
		$fileCounter++;
		if($VERBOSE){
			print("    Extracting exclusion filters ($fileCounter/$numFiles)\r");
		}
		open(GBS, "$exclusionDir/$gbs") or die "GenoScan error: Unable to read GBS file\n";
		$gbs =~ m/(chr[0-9XY]+)/;
		my $chr = "";
		$chr = $1;
		my $annotation = join("", <GBS>);
		close(GBS);
		
		#Extract annotation
		while($annotation =~ m/CDS([^\/]+)/g){
			my $cds = $1;
			$cds =~ s/\s+|<|>//g;
			while($cds =~ m/([0-9]+)\.\.([0-9]+)/g){
				push(@gbsArray, "$chr:$1-$2");
			}
		}
		while($annotation =~ m/ncRNA([^\/]+)/g){
			my $region = $1;
			while($region =~ m/([0-9]+)\.\.([0-9]+)/g){
				push(@gbsArray, "$chr:$1-$2");
			}
		}
		while($annotation =~ m/(rRNA|tRNA)([^\/]+)/g){
			my $region = $2;
			while($region =~ m/([0-9]+)\.\.([0-9]+)/g){
				push(@gbsArray, "$chr:$1-$2");
			}
		}
		
		#Merge overlapping annotations
		#Strategy: extend outer to completely cover inner and eliminate inner
		my %indToRemove;
		for(my $outer = 0; $outer < scalar(@gbsArray)-1; $outer++){
			for(my $inner = $outer+1; $inner < scalar(@gbsArray); $inner++){
				my ($outerChr, $outerStart, $outerEnd) = split(/:|-/, $gbsArray[$outer]);
				my ($innerChr, $innerStart, $innerEnd) = split(/:|-/, $gbsArray[$inner]);
				
				#outer start inside inner
				if($innerStart <= $outerStart && $outerStart <= $innerEnd){
					$outerStart = $innerStart;
					
					#outer end also inside inner
					if($outerEnd < $innerEnd){
						$outerEnd = $innerEnd;
					}
					$indToRemove{$inner} = 1;
				}
				
				#outer end inside inner
				elsif($innerStart <= $outerEnd && $outerEnd <= $innerEnd){
					$outerEnd = $innerEnd;
					$indToRemove{$inner} = 1;
				}
				
				#outer contains inner
				elsif($outerStart <= $innerStart && $innerEnd <= $outerEnd){
					$indToRemove{$inner} = 1;
				}
			}
		}
		
		#Remove inners
		for(my $index = scalar(@gbsArray)-1; $index >= 0; $index--){
			if($indToRemove{$index}){
				splice(@gbsArray, $index, 1);
			}
		}
		
		push(@annotArray, @gbsArray);
	}
	if($VERBOSE){
		print("\n");
	}
	
	#Write annotation array to annotation folder
	if(@gbs){
		open(EXC, ">$annotationDir/exclusion_filters") or die "Unable write exclusion_filters file\n";
		print(EXC join("\n", @annotArray));
		return 1;
	}
	return 0;
}

#Description: Reads file and extracts inclusion filters
#Parameters: (1) file containing inclusion filters, (2) annotation output folder, (3) verbose flag
#Return value: 1 if inclusion file is read, 0 otherwise
sub readIncFile($ $ $){
	my ($inclusionFile, $annotationDir, $VERBOSE) = @_;
	
	#Check inclusion file format
	if($VERBOSE){
		print("    Reading inclusion filters\n");
	}
	open(INC, $inclusionFile) or die "GenoScan error: Unable to read inclusion file\n";
	my @inclusion = <INC>;
	close(INC);
	my $lineCount = 0;
	foreach my $line (@inclusion){
		$lineCount++;
		if($line =~ m/^\s*$/){
			next;
		}
		if($line !~ m/chr[0-9XY]+\s*:\s*[0-9]+\s*-\s*[0-9]+/){
			die "GenoScan error: Invalid format in inclusion file line $lineCount\n";
		}
	}
	
	#Copy inclusion file to annotation folder
	if(@inclusion){
		system("cp $inclusionFile $annotationDir/inclusion_filters");
		return 1;
	}
	return 0;
}

return 1;

