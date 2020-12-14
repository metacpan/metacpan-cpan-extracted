#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More 0.89;
use Encode qw/encode decode/;

my $BOM = "\x{FEFF}";
my $text = "Hèló Wörld";

my %bom_for = (
	'8'    => "\xEF\xBB\xBF",
	'16BE' => "\xFE\xFF",
	'16LE' => "\xFF\xFE",
	'32BE' => "\x00\x00\xFE\xFF",
	'32LE' => "\xFF\xFE\x00\x00",
);

my @keys = sort { substr($a, 0, 2) <=> substr($b, 0, 2) || $a cmp $b } keys %bom_for;

for my $shortname (@keys) {
	my $encoding = "UTF-$shortname";
	subtest $encoding, sub {
		{
		my $encoded = encode($encoding, $BOM . $text);
		open my $fh, '<:bom', \$encoded or die "Couldn't open $encoding: $!";
		my $read = <$fh>;
		is($read, $text, "Input is correct with BOM");
		}

		{
		my $encoded = encode($encoding, $text);
		open my $fh, "<:bom($encoding)", \$encoded or die "Couldn't open for $encoding: $!";
		my $read = <$fh>;
		is($read, $text, "Input is correct with default");
		}

		{
		my $encoded = '';
		my $bom = $bom_for{$shortname};
		open my $fh, ">:bom($encoding)", \$encoded or die "Couldn't open for $encoding: $!";
		print $fh $text;
		close $fh;
		is(substr($encoded, 0, length $bom), $bom, "Starts with a bom " . length $bom);
		my $decoded = decode($encoding, substr $encoded, length $bom);
		is($decoded, $text, "Decoded as expected");
		}
	}
}

done_testing();
