use strict;
use warnings;
use IO::File;
use Path::Tiny qw(path);
use Test::More tests => 6;

use Pod::Tree;

my $Dir = "t/cut.d";

LoadFile("fileU");
LoadFile( "file0", 0 );
LoadFile( "file1", 1 );
LoadString("stringU");
LoadString( "string0", 0 );
LoadString( "string1", 1 );

sub LoadFile {
	my ( $dump, $in_pod ) = @_;

	my %options;
	defined $in_pod and $options{in_pod} = $in_pod;

	my $tree = Pod::Tree->new;
	$tree->load_file( "$Dir/cut.pod", %options );

	my $actual   = $tree->dump;
	my $expected = path("$Dir/$dump.exp")->slurp;
	is $actual, $expected;

	path("$Dir/$dump.act")->spew($actual);
}

sub LoadString {
	my ( $dump, $in_pod ) = @_;
	my $string = path("$Dir/cut.pod")->slurp;

	my %options;
	defined $in_pod and $options{in_pod} = $in_pod;

	my $tree = Pod::Tree->new;
	$tree->load_string( $string, %options );

	my $actual   = $tree->dump;
	my $expected = path("$Dir/$dump.exp")->slurp;
	is $actual, $expected;

	path("$Dir/$dump.act")->spew($actual);
}

sub LoadParagraphs {
	my $file       = shift;
	my $string     = path("$file.pod")->slurp;
	my @paragraphs = split m(\n{2,}), $string;
	my $tree       = Pod::Tree->new;

	$tree->load_paragraphs( \@paragraphs );

	my $actual   = $tree->dump;
	my $expected = path("$file.p_exp")->slurp;

	is $actual, $expected;
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

