package KamTest;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	ClearTimer
	CompareFile
	GetTime
	InitWorkFolder
	LoadFile
	Format
	OutPut
	Parse
	PreText
	PostText
	TestParse
	WriteCleanUp
);
use Time::HiRes qw(time);



our $workfolder;
our $outfolder;
our $reffolder;
our $samplefolder;
our $pretext = "";
our $posttext = "";
our $output = "";
our $timed = 0;

our @cleanup = ();

sub ClearTimer {
	$timed = 0;
}

sub CompareFile {
	my $file = shift;
	my $refdata = LoadFile("$reffolder/$file");
	if ($refdata eq $output) {
		return 1
	}
	return 0
}

sub Format {
	$output = "";
	my ($kam, $file) = @_;
	unless (open(OFILE, ">", "$outfolder/$file")) {
		die "Cannot open output $file"
	}
	push @cleanup, $file;
	Out($pretext);
	Out($kam->Format);
	Out($posttext);
	close OFILE;
	return $output;
}

sub GetTime {
	return $timed
}

sub InitWorkFolder {
	$workfolder = shift;
	unless (-e $workfolder) {
		die "workfolder $workfolder does not exist"
	}
	$outfolder = "$workfolder/output";
	unless (-e $outfolder) {
		mkdir $outfolder
	}
	$reffolder = "$workfolder/reference_files";
	unless (-e $reffolder) {
		die "reference folder $reffolder does not exist"
	}
	$samplefolder = "$workfolder/samples";
	unless (-e $reffolder) {
		die "sample folder $samplefolder does not exist"
	}
}

sub LoadFile {
	my $file = shift;
	my $text = '';
	unless (open(AFILE, "<", $file)) {
		warn "Cannot open $file";
		return ''
	}
	while (my $in = <AFILE>) {
		$text = $text . $in
	}
	close AFILE;
	return $text;
}

sub Out {
	my $out = shift;
	$output = $output . $out;
	print OFILE $out;
}

sub OutPut {
	my ($out, $file) = @_;
	$output = $pretext . $out . $posttext;
	unless (open(OFILE, ">", "$outfolder/$file")) {
		die "Cannot open output $file"
	}
	push @cleanup, $file;
	print OFILE $output;
	close OFILE;
}

sub Parse {
	my ($kam, $samplefile) = @_;
	unless (open(IFILE, "<", "$samplefolder/$samplefile")) {
		die "Cannot open input $samplefile"
	}
	while (my $in = <IFILE>) {
		my $starttime = time;
		$kam->Parse($in);
		my $endtime = time;
		$timed = $timed + ($endtime - $starttime);
	}
	close IFILE;
}

sub PreText {
	$pretext = shift;
}

sub PostText {
	$posttext = shift;
}

sub TestParse {
	my ($kam, $samplefile, $outfile) = @_;
	Parse($kam, $samplefile);
	Format($kam, $outfile);
	return CompareFile($outfile);
}

sub WriteCleanUp {
	my $file = "$workfolder/CLEANUP";
	unless (open(OFILE, ">", $file)) {
		die "Cannot open output $file"
	}
	for (@cleanup) {
		print OFILE "$_\n";
	}
	close OFILE;
}

1;
