package Report_HTML_DB::Repositories::BlastRepository;
use Moose;

=pod

This repository is responsible to execute functions related with the BLAST tool

executeBlastSearch is used to execute search of the blast tool, 
using external parameters, mount the command line, and returns the reference of String
$program				=>	scalar with the name of the program
$database				=>	scalar with the database
$fastaSequence			=>	scalar with the sequence
$from					=>	scalar from position sequence
$to						=>	scalar to position sequence
$filter					=>	referenced list with filters
$expect					=>	scalar with the expected evalue
$matrix					=>	scalar with matrix
$ungappedAlignment		=>	scalar with off or on for ungapped alignments
$geneticCode			=>	scalar with the genetic code
$databaseGeneticCode	=>	scalar with the database genetic code
$frameShiftPenality		=>	scalar with the frame shift penality option
$alignmentView			=>	scalar with the alignment view
$descriptions			=>	scalar with the quantity of descriptions
$alignments				=>	scalar with the quantity of alignments
$costOpenGap            =>  scalar with the cost to open gap
$costToExtendGap        =>  scalar with the cost to extend a gap
$wordSize               =>  scalar with the word size

=cut

sub executeBlastSearch {
	my (
		$self,              $blast,         $database,
		$fastaSequence,     $from,          $to,
		$filter,            $expect,        $matrix,
		$ungappedAlignment, $geneticCode,   $databaseGeneticCode,
		$alignmentView,     $descriptions,  $alignments,
        $costOpenGap,       $costToExtendGap,   $wordSize
	) = @_;

	my $command =
	  "$blast -query \"$fastaSequence\" -db \"$database\" -show_gis ";
	$command .= " -query_loc \"" . $from . "-" . $to . "\" " if $from && $to;
	$command .= " -evalue \"$expect\" "                      if $expect;
	$command .= " -matrix \"$matrix\" "
	  if $matrix
	  && ( $blast eq "blastp"
		|| $blast eq "blastx"
		|| $blast eq "tblastn"
		|| $blast eq "tblastx" );

	$command .= " -ungapped " if $ungappedAlignment && $blast eq "blastn";
	$command .= " -query_gencode \"$geneticCode\" "
	  if $geneticCode && $blast eq "blastx";
	$command .= " -db_gencode \"$databaseGeneticCode\" "
	  if $databaseGeneticCode
	  && ( $blast eq "tblastn" || $blast eq "tblastx" );

    if ($filter) {
        if(ref $filter =~ /ARRAY/) {
            my @list = @$filter;
            foreach my $value (@list) {
                if($value eq 'L') {
                    if ($blast eq "blastn") {
                        $command .= " -dust 'yes' ";
                    } else {
                        $command .= " -seg 'yes' ";
                    }
                }
            }
        } else {
            if($filter eq 'L') {
                if($blast eq "blastn") {
                    $command .= " -dust 'yes' ";
                } else {
                    $command .= " -seg 'yes' ";
                }
            }
        }
    }
    if($blast eq "blastn") {
        if ($costOpenGap) {
            $command .= " -gapopen $costOpenGap ";
        } else {
            $command .= " -gapopen 5 ";
        }
        if ($costToExtendGap) {
            $command .= " -gapextend $costToExtendGap ";
        } else {
            $command .= " -gapextend 2";
        }
        if($wordSize) {
            $command .= " -word_size $wordSize ";
        } else {
            $command .= " -word_size 11 ";
        }
    } elsif ($blast eq "blastp" ||
             $blast eq "blastx" ||
             $blast eq "tblastn") {
        if ($costOpenGap) {
            $command .= " -gapopen $costOpenGap ";
        } else {
            $command .= " -gapopen 11 ";
        }
        if ($costToExtendGap) {
            $command .= " -gapextend $costToExtendGap ";
        } else {
            $command .= " -gapextend 1";
        }
        if($wordSize) {
            $command .= " -word_size $wordSize ";
        } else {
            $command .= " -word_size 3 ";
        } 
    }

	$command .= " -num_descriptions \"$descriptions\" " if $descriptions;
	$command .= " -num_alignments \"$alignments\" " if $alignments;
	$command .= " -outfmt 0 " if !$alignmentView || undef $alignmentView;
	$command .= " -outfmt \"$alignmentView\" " if $alignmentView;
	print STDERR "\n$command\n";
	my @response = `$command`;

	#	my $content = join( "", @response );
	#	print "\n".$content."\n";
	return \@response;
}

sub fancyBlast {
	my ( $self, $blast, $output, $database ) = @_;
	my $status = 0;
	$database = " no_code " if !$database || !defined $database;
	if ( ( $blast && defined($blast) ) && ( $output && defined($output) ) ) {
		`fancy_blast.pl "$blast" "$output" "$database"`;
		$status = 1;
		return $status;
	}
	return $status;
}

1;
