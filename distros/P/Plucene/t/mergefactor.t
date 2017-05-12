#!/usr/bin/perl -w

use strict;
use warnings;

use Plucene::Index::Writer;
use Plucene::Analysis::SimpleAnalyzer;
use File::Path;
use File::Temp qw/tempdir/;

use Test::More tests => 4;

use constant DIRECTORY => tempdir();

END { rmtree DIRECTORY }

{
	my $writer =
		Plucene::Index::Writer->new(DIRECTORY,
		Plucene::Analysis::SimpleAnalyzer->new(), 1);

	is $writer->mergefactor => 10, "Original mergefactor of 10";
	$writer->set_mergefactor(5);
	is $writer->mergefactor => 5, "New mergefactor of 5";
	$writer->set_mergefactor;
	is $writer->mergefactor => 5, "mergefactor still 5";
	undef $writer->{mergefactor};
	$writer->set_mergefactor;
	is $writer->mergefactor => 10, "mergefactor now 10";
}
