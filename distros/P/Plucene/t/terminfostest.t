#!/usr/bin/perl -w

use strict;
use warnings;

use File::Path;
use File::Temp qw/tempdir/;

use constant DIRECTORY => tempdir();
use Plucene::Index::FieldInfos;

END { rmtree DIRECTORY }

use File::Slurp;

use Test::More qw(no_plan);
use_ok("Plucene::Index::TermInfosWriter");
use_ok("Plucene::Index::TermInfosReader");
use_ok("Plucene::Index::Term");

my @keys = map {
	chomp;
	return () unless $_;
	Plucene::Index::Term->new({ field => "word", text => $_ })
} read_file('t/words.txt');

# Generate random segment
my $fp = int rand(8);
my $pp = int rand(8);
my (@doc_freqs, @freq_pointers, @prox_pointers);
for my $i (0 .. $#keys) {
	$doc_freqs[$i]     = int rand(8);
	$freq_pointers[$i] = $fp;
	$prox_pointers[$i] = $pp;
	$fp += int rand(8);
	$pp += int rand(8);
}

my $fis = Plucene::Index::FieldInfos->new;

{
	my $writer = Plucene::Index::TermInfosWriter->new(DIRECTORY, "words", $fis);
	$fis->add("word", 0);

	for (0 .. $#keys) {
		$writer->add(
			$keys[$_],
			Plucene::Index::TermInfo->new({
					doc_freq     => $doc_freqs[$_],
					freq_pointer => $freq_pointers[$_],
					prox_pointer => $prox_pointers[$_] }));
	}

	$writer->break_ref;

}

my $size = -s DIRECTORY . "/words.tis";
ok($size, "Wrote index of $size bytes");

my $reader = Plucene::Index::TermInfosReader->new(DIRECTORY, "words", $fis);
isa_ok($reader, "Plucene::Index::TermInfosReader", "Got reader");
my $enum = $reader->terms;
isa_ok($enum, "Plucene::Index::SegmentTermEnum", "Got term enum");
for my $i (0 .. $#keys) {
	$enum->next;
	my $key = $keys[$i];
	is_deeply($enum->term, $key, "Key $i matches");
	my $ti = $enum->term_info;
	is($ti->doc_freq, $doc_freqs[$i], "Doc frequency at $i matches");
	is($ti->freq_pointer, $freq_pointers[$i],
		"Frequency pointer at $i matches");
	is($ti->prox_pointer, $prox_pointers[$i],
		"Proximity pointer at $i matches");
}

