#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;
use Perl::Minify qw(minify minify_sub minify_error);
use Getopt::Long;

my $width = 0;
my $sub_name;
GetOptions(
	'width=i' => \$width,
	'sub=s'   => \$sub_name,
) or die(usage());

###############################################################################
###############################################################################

# Read the sample source file
my $source_file = $ARGV[0] || "";

if (!-r $source_file) {
	die(usage());
}

my $source = file_get_contents($source_file);

# Minify the file (or just one sub, if --sub was given)
my $opts = { shorten_vars => 1, wrap => $width };
my $min;
if (defined $sub_name) {
	$min = minify_sub($source, $sub_name, $opts);
} else {
	$min = minify($source, $opts);
}

if (!defined $min) {
	print STDERR minify_error(), "\n";
	exit 1;
}

print $min;

###############################################################################
###############################################################################

sub usage {
	my $ret = "Usage: $0 script.pl [--width 80] [--sub NAME]\n";

	return $ret;
}

sub file_get_contents {
	my ($file) = @_;

	open(my $fh, "<", $file) or return undef;
	binmode($fh, ":encoding(UTF-8)");

	local $/ = undef; # Slurp
	my $ret = readline($fh);
	close($fh);

	return $ret;
}

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
