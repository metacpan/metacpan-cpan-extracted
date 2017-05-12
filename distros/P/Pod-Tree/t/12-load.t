use strict;
use warnings;
use IO::File;
use Path::Tiny qw(path);
use Test::More tests => 3;

use Pod::Tree;

my $Dir = "t/load.d";

LoadFH("$Dir/list");
LoadString("$Dir/list");
LoadParagraphs("$Dir/list");

sub LoadFH {
	my $file = shift;
	my $fh   = IO::File->new;
	my $tree = Pod::Tree->new;
	$fh->open("$file.pod") or die "Can't open $file.pod: $!\n";
	$tree->load_fh($fh);

	my $actual   = $tree->dump;
	my $expected = path("$file.exp")->slurp;
	is $actual, $expected;

	path("$file.act")->spew($actual);
}

sub LoadString {
	my $file   = shift;
	my $string = path("$file.pod")->slurp;
	my $tree   = Pod::Tree->new;
	$tree->load_string($string);

	my $actual   = $tree->dump;
	my $expected = path("$file.exp")->slurp;
	is $actual, $expected;
}

sub LoadParagraphs {
	my $file       = shift;
	my @paragraphs = ReadParagraphs("$file.pod");
	my $tree       = Pod::Tree->new;

	$tree->load_paragraphs( \@paragraphs );

	my $actual   = $tree->dump;
	my $expected = path("$file.exp")->slurp;

	is $actual, $expected;
}

sub ReadParagraphs {
	my $file   = shift;
	my $pod    = path($file)->slurp;
	my @chunks = split /(\n{2,})/, $pod;

	my @paragraphs;
	while (@chunks) {
		push @paragraphs, join '', splice @chunks, 0, 2;
	}

	@paragraphs;
}

sub Split {
	my $string = shift;
	my @pieces = split /(\n{2,})/, $string;

	my @paragraphs;
	while (@pieces) {
		my ( $text, $ending ) = splice @pieces, 0, 2;
		$ending or $ending = '';    # to quiet -w
		push @paragraphs, $text . $ending;
	}

	@paragraphs;
}

