;#!/usr/bin/perl
#
# Example script that sanitizes a log file, such as that created by
# screen(1) or script(1) (or even one of Term::VT102's other example
# scripts).
#
# Any cursor positioning and other control codes are removed, leaving only
# complete lines of text, optionally including ANSI/ECMA-48 colour and
# attribute change sequences.
#
# Arguments are <width> <height> [colour|plain] - if nothing is provided,
# the default is to assume an 80x24 terminal with colour output.
#
# Data is read from standard input and written to standard output.
#

use Term::VT102;
use strict;

my ($width, $height, $colour) = @ARGV;
$width = 80 if ((not defined $width) || ($width !~ /^\d+$/));
$height = 24 if ((not defined $height) || ($height !~ /^\d+$/));
$colour = (defined $colour && $colour !~ /^(colour|color)$/) ? 0 : 1;

my $vt = Term::VT102->new ('cols' => $width, 'rows' => $height);
$vt->option_set ('LFTOCRLF', 1);
$vt->option_set ('LINEWRAP', 1);

$vt->callback_set ('GOTO', \&vt_callback, $colour);
$vt->callback_set ('LINEFEED', \&vt_callback, $colour);

while (<STDIN>) {
	$vt->process ($_);
}


sub vt_callback {
	my ($vtobject, $type, $arg1, $arg2, $private) = @_;

	if ($type eq 'GOTO') {
		$arg2 = $vtobject->rows if ($arg2 > $vtobject->rows);
		return if ($arg2 <= $vtobject->y);
		for (my $y = $vtobject->y; $y < $arg2; $y++) {
			print "\n";
		}
	} elsif ($type eq 'LINEFEED') {
		my $line = $private ? $vtobject->row_sgrtext ($arg1) : $vtobject->row_plaintext ($arg1);
		$line =~ s/\s+$//;
		print '' . $line . "\n";
	}
}

# EOF
