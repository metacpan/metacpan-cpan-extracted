package Software::GenoScan::InputProcessor;

use warnings;
use strict;

use Software::GenoScan::Segmentor qw(segmentize);
require Exporter;

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	processInput
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

#RNAfold command
my $RNAfold;

#Description: Wrapper function for processing input sequences
#Parameters: (1) input directory, (2) output directory, (3) verbose flag, (4) log array
#Return value: None
sub processInput($ $ $ $){
	my ($INPUT_DIR, $OUTPUT_DIR, $VERBOSE, $logArray) = @_;
	if(! -e $OUTPUT_DIR){
		system("mkdir $OUTPUT_DIR");
	}
	if(! -e "$OUTPUT_DIR/step_2"){
		system("mkdir $OUTPUT_DIR/step_2");
	}
	if(! -e "$OUTPUT_DIR/step_2/chunks"){
		system("mkdir $OUTPUT_DIR/step_2/chunks");
	}
	if(! -e "$OUTPUT_DIR/step_2/folded"){
		system("mkdir $OUTPUT_DIR/step_2/folded");
	}
	if(! -e "$OUTPUT_DIR/step_2/substring"){
		system("mkdir $OUTPUT_DIR/step_2/substring");
	}
	push(@{$logArray}, "Step 2: segmentize and fold input sequences\n");
	
	#Detect input sequence files
	if(! -e $INPUT_DIR){
		die "GenoScan error: Unable to find input sequence directory '$INPUT_DIR'\n";
	}
	$INPUT_DIR =~ s/\/+$//;
	my @files = split(/\n+/, qx(ls $INPUT_DIR));
	my @seqFiles = grep(/[^~]$/, @files);
	my $numSeqFiles = scalar(@seqFiles);
	if($VERBOSE){
		print("    $numSeqFiles input sequence file(s) detected\n");
	}
	if($numSeqFiles == 0){
		print("GenoScan: no input files detected, terminaing\n");
		exit;
	}
	push(@{$logArray}, "\t$numSeqFiles input sequence file(s) detected\n");
	
	#Read annotation
	my %excFilters;
	my %excStartPos;
	my %incFilters;
	my %incStartPos;
	if(-e "$OUTPUT_DIR/step_1/exclusion_filters"){
		if($VERBOSE){
			print("    Exclusion filters found\n");
		}
		open(EXC, "$OUTPUT_DIR/step_1/exclusion_filters") or die "GenoScan error: Unable to read exclusion_filters file\n";
		my @rows = <EXC>;
		close(EXC);
		foreach my $row (@rows){
			if($row =~ m/^\s*$/){
				next;
			}
			$row =~ s/\s+//g;
			my ($chr, $start, $stop) = split(/:|-/, $row);
			if(!$excFilters{$chr}){
				$excFilters{$chr} = [[$start, $stop]];
				$excStartPos{$chr} = [$start];
			}
			else{
				push(@{$excFilters{$chr}}, [$start, $stop]);
				push(@{$excStartPos{$chr}}, $start);
			}
		}
	}
	if(-e "$OUTPUT_DIR/step_1/inclusion_filters"){
		if($VERBOSE){
			print("    Inclusion filters found\n");
		}
		open(EXC, "$OUTPUT_DIR/step_1/inclusion_filters") or die "GenoScan error: Unable to read inclusion_filters file\n";
		my @rows = <EXC>;
		close(EXC);
		foreach my $row (@rows){
			if($row =~ m/^\s*$/){
				next;
			}
			$row =~ s/\s+//g;
			my ($chr, $start, $stop) = split(/:|-/, $row);
			if(!$incFilters{$chr}){
				$incFilters{$chr} = [[$start, $stop]];
				$incStartPos{$chr} = [$start];
			}
			else{
				push(@{$incFilters{$chr}}, [$start, $stop]);
				push(@{$incStartPos{$chr}}, $start);
			}
		}
	}
	
	#Ensure that, for each chromosome, exc/inc filters are ordered w.r.t. nucleotide position
	foreach my $chr (keys(%excFilters)){
		my @startPos = @{$excStartPos{$chr}};
		my @excIndices = sort {$startPos[$a] <=> $startPos[$b]} (0 .. $#startPos);
		@{$excFilters{$chr}} = @{$excFilters{$chr}}[@excIndices];
	}
	foreach my $chr (keys(%incFilters)){
		my @startPos = @{$incStartPos{$chr}};
		my @incIndices = sort {$startPos[$a] <=> $startPos[$b]} (0 .. $#startPos);
		@{$incFilters{$chr}} = @{$incFilters{$chr}}[@incIndices];
	}
	
	#Extract input sequence substring (1) not excluded and (2) included
	my @manifestFiles;
	my @filterFlags;
	foreach my $file (@seqFiles){
		
		#Read chromosome sequence
		open(CHR, "$INPUT_DIR/$file") or die "GenoScan error: Unable to read input sequence file '$INPUT_DIR/$file'\n";
		my $seq = join("", <CHR>);
		$seq =~ s/\r|\r\n|\n\r/\n/g;
		close(CHR);
		
		#Extract and remove header
		$seq =~ m/^([^\n]+)/;
		my $header = $1;
		my $headerPattern = $header;
		$headerPattern =~ s/\|/\\|/g;
		$seq =~ s/^$headerPattern\n//;
		
		#Remove newlines and determine seq length
		$seq =~ s/\s+//g;
		my $seqLen = length($seq);
		
		#Determine chromosome name
		my $chr = "chr";
		if($header =~ m/chromosome ([0-9XYxy]+)/){
			$chr = "chr$1";
		}
		elsif($header =~ m/^>([0-9XYxy]+)/){
			$chr = "chr$1";
		}
		
		#If no filters
		if(!$excFilters{$chr} && !$incFilters{$chr}){
			push(@manifestFiles, "$INPUT_DIR/$file\n$file");
			push(@filterFlags, 0);
			next;
		}
		push(@filterFlags, 1);
		
		#Write substrings file
		open(SUB, ">$OUTPUT_DIR/step_2/substring/$file") or die "GenoScan error: Unable to write '$OUTPUT_DIR/step_2/substring/$file'\n";
		push(@manifestFiles, "$OUTPUT_DIR/step_2/substring/$file\n$file");
		
		#If exlusion filters, substring outside them
		my @substrings;
		if($excFilters{$chr}){
			my @excRegions = @{$excFilters{$chr}};
			my $startNuc = 0;	#start position for substr
			my $endNuc;			#end position for substr
			my $subHeader;		#substring header
			my $substr;			#substring of chromosome sequence
			my $subStart;		#start position for header
			my $subEnd;			#end position for header
			foreach my $region (@excRegions){
				my ($regStart, $regEnd) = @{$region};
				$endNuc = $regStart - 2;
				$subStart = $startNuc + 1;
				$subEnd = $endNuc + 1;
				$subHeader = $header;
				$substr = substr($seq, $startNuc, $endNuc - $startNuc + 1);
				if(length($substr) < 200){
					$startNuc = $regEnd;
					next;
				}
				push(@substrings, "$subHeader\n$subStart\n$subEnd\n$substr");
				$startNuc = $regEnd;
			}
			
			#After last region to end of chromosome
			$subStart = $startNuc + 1;
			$subEnd = $seqLen;
			$subHeader = $header;
			$substr = substr($seq, $startNuc, $subEnd - $startNuc);
			if(length($substr) >= 200){
				push(@substrings, "$subHeader\n$subStart\n$subEnd\n$substr");
			}
		}
		
		#If only exlusion filters, write substrings to file
		if($excFilters{$chr} && !$incFilters{$chr}){
			print(SUB join("\n", @substrings));
		}
		
		#If exlusion and inclusion filters, discard/trunkate substrings that do not overlap with inclusion filters before writing to substring file
		if($excFilters{$chr} && $incFilters{$chr}){
			my @incRegions = @{$incFilters{$chr}};
			my @substrPass;
			foreach my $sub (@substrings){
				my ($header, $subStart, $subEnd, $substr) = split(/\n/, $sub);
				foreach my $reg (@incRegions){
					my ($regStart, $regEnd) = @{$reg};
					my $overlap = 0;
					
					#Complete within inclusion region
					if($regStart <= $subStart && $subEnd <= $regEnd){
						push(@substrPass, $sub);
						last;
					}
					
					#Left part of substring outside inclusion region, trunkate
					if($subStart < $regStart && $regStart < $subEnd){
						my $diff = $regStart - $subStart;
						$subStart = $regStart;
						$substr = substr($substr, $diff);
						$overlap = 1;
					}
					
					#Right part of substring outside inclusion region, trunkate
					if($subStart < $regEnd && $regEnd < $subEnd){
						my $diff = $subEnd - $regEnd;
						$subEnd = $regEnd;
						$substr = substr($substr, 0, length($substr) - $diff);
						$overlap = 1;
					}
					
					#If partial overlap
					if($overlap && length($substr) >= 200){
						push(@substrPass, "$header\n$subStart\n$subEnd\n$substr");
					}
				}
			}
			print(SUB join("\n", @substrPass));
		}
		
		#If only inclusion filters
		if(!$excFilters{$chr} && $incFilters{$chr}){
			my @incRegions = @{$incFilters{$chr}};
			foreach my $reg (@incRegions){
				my ($regStart, $regEnd) = @{$reg};
				my $subHeader = "$header substring $regStart-$regEnd";
				my $substr = substr($seq, $regStart - 1, $regEnd - $regStart + 1);
				if(length($substr) >= 200){
					push(@substrings, "$subHeader\n$regStart\n$regEnd\n$substr");
				}
			}
			print(SUB join("\n", @substrings));
		}
		close(SUB);
	}
	
	#Write chromosome/substring file paths to manifest
	open(MAN, ">$OUTPUT_DIR/step_2/manifest") or die "GenoScan error: Unable to write input manifest";
	print(MAN join("\n", @manifestFiles));
	close(MAN);
	
	#Segmentize input sequence files
	segmentize(\@filterFlags, "$OUTPUT_DIR/step_2/manifest", "$OUTPUT_DIR/step_2/chunks/", $VERBOSE);
	my @chunks = split(/\s+/, qx(ls $OUTPUT_DIR/step_2/chunks));
	my $numChunks = scalar(@chunks);
	if($VERBOSE){
		print("    $numChunks chunk(s) generated\n");
	}
	if($numChunks == 0){
		die "GenoScan: No chunks generated, terminating\n";
	}
	push(@{$logArray}, "\t$numChunks chunk(s) generated\n\n");
	
	#Fold chunks
	my $chunkCounter = 0;
	foreach my $chunk (@chunks){
		$chunkCounter++;
		if($VERBOSE){
			$| = 1;
			print("    Folding chunk $chunkCounter/$numChunks\r");
		}
		
		#Read chunk
		open(CHUNK, "$OUTPUT_DIR/step_2/chunks/$chunk") or die "GenoScan error: Unable to read chunk file\n";
		my $chunkContents = join("", <CHUNK>);
		close(CHUNK);
		my @chunkContents = split(/\n\n/, $chunkContents);
		my @passChunks;
		foreach my $win (@chunkContents){
			my ($header, $seq) = split(/\n/, $win);
			if($seq =~ m/N/i){
				next;
			}
			$seq =~ tr/ATGCatgc/UACGuacg/;
			push(@passChunks, "$header\n$seq");
		}
		
		#Rewrite chunk as RNA transcript of DNA
		open(CHUNK, ">$OUTPUT_DIR/step_2/chunks/$chunk") or die "GenoScan error: Unable to write RNA chunk file\n";
		print(CHUNK join("\n\n", @passChunks));
		close(CHUNK);
		
		#Run RNAfold, check if run is successful
		my $result = qx($RNAfold < $OUTPUT_DIR/step_2/chunks/$chunk);
		my @folds = split(/>/, $result);
		shift(@folds);
		
		#Process folded sequences
		my @passFolded;
		for(my $winIndex = 0; $winIndex < scalar(@passChunks); $winIndex++){
			my ($header, $seq) = split(/\n/, $passChunks[$winIndex]);
			my ($h, $s, $secstr) = split(/\n/, $folds[$winIndex]);
			push(@passFolded, "$header\n$seq\n$secstr");
		}
		my $name = $chunk;
		$name =~ s/txt$/folded/;
		open(FOLDED, ">$OUTPUT_DIR/step_2/folded/$name") or die "GenoScan error: Unable to write RNA chunk file\n";
		print(FOLDED join("\n\n", @passFolded));
		close(FOLDED);
	}
	if($VERBOSE){
		print("\n");
	}
}

#Description: Sets the RNAfold running command
#Parameters: (1) RNAfold command
#Return value: None
sub commandRNAfold($){
	$RNAfold = shift(@_);
}

return 1;
