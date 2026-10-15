#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

###############################################################################
###############################################################################

my $str = color('white', "Hello");

###############################################################################
###############################################################################

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
	my ($str, $txt) = @_;

	state $notty = !-t STDOUT;                                   # Cache the TTY check
	if ($notty || $ENV{NO_COLOR})         { return $txt // ""; } # No interactive terminal
	if (!length($str) || $str eq 'reset') { return "\e[0m";    } # No string = RESET

	# Some predefined colors/commands
	state %color_map = qw(red 160 blue 27 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
	state %cmd_map   = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);

	# Pre-process the string
	$str =~ s/on_/-/g;                             # "on_" becomes a negative number
	$str =~ s|([A-Za-z]+)|$color_map{$1} // $1|eg; # color name -> number

	my @parts = map { # If it's negative it's a background color, otherwise foreground
		$cmd_map{$_} // ($_ =~ /^-(.+)/ ? "48;5;$1" : "38;5;$_")
	} split("_", $str);

	my $ret = "\e[" . join(";", @parts) . "m";

	if (defined $txt) { $ret .= $txt . "\e[0m"; }

	return $ret;
}

sub file_get_contents {
	open(my $fh, "<", $_[0]) or return undef;
	binmode($fh, ":encoding(UTF-8)");

	my $array_mode = ($_[1]) || (!defined($_[1]) && wantarray);

	if ($array_mode) { # Line mode
		my @lines  = readline($fh);

		# Right trim all lines
		foreach my $line (@lines) { $line =~ s/[\r\n]+$//; }

		return @lines;
	} else { # String mode
		local $/       = undef; # Input rec separator (slurp)
		return my $ret = readline($fh);
	}
}

sub file_put_contents {
	my ($file, $data) = @_;

	open(my $fh, ">", $file) or return undef;
	binmode($fh, ":encoding(UTF-8)");
	print $fh $data;
	close($fh);

	return length($data);
}

# Creates methods k() and kd() to print, and print & die respectively
BEGIN {
	if (!defined(&trim)) {
		*trim = sub {
			my ($s) = (@_, $_); # Passed in var, or default to $_
			if (length($s) == 0) { return ""; }
			$s =~ s/^\s*//;
			$s =~ s/\s*$//;

			return $s;
		}
	}

	if (eval { require Dump::Krumo }) {
		Dump::Krumo->import(qw/k kd/);
	} else {
		require Data::Dumper;
		*k  = sub { print Data::Dumper::Dumper(\@_) };
		*kd = sub { print Data::Dumper::Dumper(\@_); die; };
	}
}

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
