package Software::GenoScan::CommandProcessor;

use warnings;
use strict;

require Exporter;

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	processCmd
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

#Description: Processes command line arguments
#Parameters: (1) hash containing reference to @ARGV and argument variables
#Return value: Commands hash
sub processCmd{
	my %args = @_;
	my %commands = (
		"-m"                   => {"numArgs" => 1, "validArgs" => 'genome|classify|benchmark|retrain', "var" => $args{"MODE"}},
		"--mode"               => {"numArgs" => 1, "validArgs" => 'genome|classify|benchmark|retrain', "var" => $args{"MODE"}},
		"-d"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"INPUT_DIR"}},
		"--input-dir"          => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"INPUT_DIR"}},
		"-e"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"ANNOT_EXCLUSION_DIR"}},
		"--exc-filter-dir"     => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"ANNOT_EXCLUSION_DIR"}},
		"-i"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"ANNOT_INCLUSION_FILE"}},
		"--inc-filter-file"    => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"ANNOT_INCLUSION_FILE"}},
		"-t"                   => {"numArgs" => 1, "validArgs" => '^(0(\.[0-9]+)?)|1$', "var" => $args{"PROBABILITY_THRESHOLD"}},
		"--threshold"          => {"numArgs" => 1, "validArgs" => '^(0(\.[0-9]+)?)|1$', "var" => $args{"PROBABILITY_THRESHOLD"}},
		"-f"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"HP_EXTRACTION_FILE"}},
		"--parameter-file"     => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"HP_EXTRACTION_FILE"}},
		"-p"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"POS_DATASET"}},
		"--pos-dataset"        => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"POS_DATASET"}},
		"-n"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"NEG_DATASET"}},
		"--neg-dataset"        => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"NEG_DATASET"}},
		"-g"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"GEN_DATASET"}},
		"--gen-dataset"        => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"GEN_DATASET"}},
		"-a"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"SCRIPT_PATH"}},
		"--script-path"        => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"SCRIPT_PATH"}},
		"-s"                   => {"numArgs" => 1, "validArgs" => 'hsa', "var" => $args{"SPECIES_CODE"}},
		"--species"            => {"numArgs" => 1, "validArgs" => 'hsa', "var" => $args{"SPECIES_CODE"}},
		"-l"                   => {"numArgs" => 1, "validArgs" => '^(0(\.[0-9]+)?)|1$', "var" => $args{"LOW_COMPLEXITY"}},
		"--low-complexity"     => {"numArgs" => 1, "validArgs" => '^(0(\.[0-9]+)?)|1$', "var" => $args{"LOW_COMPLEXITY"}},
		"-o"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"OUTPUT_DIR"}},
		"--output-dir"         => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"OUTPUT_DIR"}},
		"-r"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"REGRESSION"}},
		"--regression"         => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"REGRESSION"}},
		"-c"                   => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"CLASSIFY_SET"}},
		"--classify-set"       => {"numArgs" => 1, "validArgs" => '.+', "var" => $args{"CLASSIFY_SET"}},
		"-v"                   => {"numArgs" => 0, "var" => $args{"VERBOSE"}, "value" => 1},
		"--verbose"            => {"numArgs" => 0, "var" => $args{"VERBOSE"}, "value" => 1},
		"-j"                   => {"numArgs" => 1, "validArgs" => '^[2-5]$', "var" => $args{"JUMP"}},
		"--jump"               => {"numArgs" => 1, "validArgs" => '^[2-5]$', "var" => $args{"JUMP"}},
		"-h"                   => {"numArgs" => 0, "sub" => \&commandHelp},
		"--help"               => {"numArgs" => 0, "sub" => \&commandHelp}
	);
	my @commandLine = @{$args{"commandline"}};
	chomp(@commandLine);
	my @allCommands = @commandLine;
	if(!@commandLine){
		commandHelp();
	}
	while(@commandLine){
		my $com = shift(@commandLine);
		my $arg;
		if(!$commands{$com}){
			die "GenoScan error: Unrecognized command '$com'\n";
		}
		if($commands{$com}{"numArgs"} == 1){
			$arg = shift(@commandLine);
			if($arg =~ /^-/){
				die "GenoScan error: Missing argument for command '$com'\n";
			}
			my $valid = $commands{$com}{"validArgs"};
			if($arg !~ /$valid/){
				die "GenoScan error: Invalid argument '$arg' to '$com'\n";
			}
		}
		if($commands{$com}{"var"}){
			if($commands{$com}{"value"}){
				${$commands{$com}{"var"}} = $commands{$com}{"value"};
			}
			else{
				${$commands{$com}{"var"}} = $arg;
			}
		}
		if($commands{$com}{"sub"}){
			&{$commands{$com}{"sub"}}($arg, \@allCommands);
		}
	}
	checkManArgMode(${$args{"MODE"}}, \@allCommands);
	return %commands;
}

#Description: Checks that mandatory arguments are supplied
#Parameters: (1) The -m argument, (2) command line arguments
#Return value: None
sub checkManArgMode{
	my ($mode, $comLineRef) = @_;
	my $commands = join(" ", @{$comLineRef});
	if($mode eq "genome"){
		my $foundDJ = 0;
		my $foundO = 0;
		if($commands =~ m/-d\s+[^\s]/ || $commands =~ m/--input-dir\s+[^\s]/ || $commands =~ m/-j\s+[3-5]/ || $commands =~ m/--jump\s+[3-5]/){
			$foundDJ = 1;
		}
		if($commands =~ m/-o\s+[^\s]/ || $commands =~ m/--output-dir\s+[^\s]/){
			$foundO = 1;
		}
		if(!$foundDJ || !$foundO){
			die "GenoScan error: Command line options -d and -o must be given when running in genome mode\n";
		}
	}
	elsif($mode eq "classify"){
		my $foundO = 0;
		my $foundC = 0;
		if($commands =~ m/-o\s+[^\s]/ || $commands =~ m/--output-dir\s+[^\s]/){
			$foundO = 1;
		}
		if($commands =~ m/-c\s+[^\s]/ || $commands =~ m/--classify-set\s+[^\s]/){
			$foundC = 1;
		}
		if(!$foundO || !$foundC){
			die "GenoScan error: Command line options -o and -c must be given when running in classify mode\n";
		}
	}
	elsif($mode eq "benchmark"){
		my $foundO = 0;
		my $foundP = 0;
		my $foundN = 0;
		my $foundG = 0;
		if($commands =~ m/-o\s+[^\s]/ || $commands =~ m/--output-dir\s+[^\s]/){
			$foundO = 1;
		}
		if($commands =~ m/-p\s+[^\s]/ || $commands =~ m/--pos-dataset\s+[^\s]/){
			$foundP = 1;
		}
		if($commands =~ m/-n\s+[^\s]/ || $commands =~ m/--neg-dataset\s+[^\s]/){
			$foundN = 1;
		}
		if($commands =~ m/-g\s+[^\s]/ || $commands =~ m/--gen_dataset\s+[^\s]/){
			$foundG = 1;
		}
		if(!$foundO || !$foundP || !$foundN || !$foundG){
			die "GenoScan error: Command line options -o, -p, -n and -g must be given when running in classify mode\n";
		}
	}
	elsif($mode eq "retrain"){
		my $foundO = 0;
		my $foundP = 0;
		my $foundN = 0;
		if($commands =~ m/-o\s+[^\s]/ || $commands =~ m/--output-dir\s+[^\s]/){
			$foundO = 1;
		}
		if($commands =~ m/-p\s+[^\s]/ || $commands =~ m/--pos-dataset\s+[^\s]/){
			$foundP = 1;
		}
		if($commands =~ m/-n\s+[^\s]/ || $commands =~ m/--neg-dataset\s+[^\s]/){
			$foundN = 1;
		}
		if(!$foundO || !$foundP || !$foundN){
			die "GenoScan error: Command line options -o, -p and -n must be given when running in classify mode\n";
		}
	}
}

#Description: Command line help
#Parameters: None
#Return value: None
sub commandHelp(){
	my $doc = <<END;
Usage
    perl genoscan.pl [Options]

Version $VERSION

Options
    General

    -m, --mode               GenoScan running mode [genome|classify|benchmark|retrain]
    -t, --threshold          Probability threshold for hairpin classification (0 to 1)
    -r, --regression         Name of custom regression model parameter file
    -o, --output-dir         Name of output directory
    -s, --species            Species code [hsa]
    -l, --low-complexity     Percentage threshold for low-complexity filtering (0 to 1)
    -v, --verbose            Report progress during GenoScan run
    -h, --help               Print command line help
    
    Genome mode only
    
    -d, --input-dir          Directory containing FASTA files to scan for miRNAs
    -e, --exc-filter-dir     Directory containing GBS annotation files
    -i, --inc-filter-file    Name of file containing regions to include in the scan
    -f, --parameter-file     Name of file containing hairpin extraction parameters
    -j, --jump               Start processing on GenoScan step [2-5]
    
    Classify mode only
    
    -c, --classify-set       FASTA file containing hairpins to classify
    
    Benchmark and retrain mode only
    
    -p, --pos-dataset        Positive dataset file
    -n, --neg-dataset        Negative dataset file
    -g, --gen-dataset        Genomic dataset file (benchmark only)
    -a, --script-path        Custom path to R-script used for benchmark/retrain

Output
    miRNA_candidates:        List of hairpins that pass the probability threshold
    log:                     Summary of GenoScan run
END
	die "$doc\n";
}

return 1;

