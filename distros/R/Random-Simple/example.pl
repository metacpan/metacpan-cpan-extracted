#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use Random::Simple;
use Getopt::Long;

my $debug = 0;

GetOptions(
	'debug' => \$debug,
);

$Random::Simple::debug = $debug;

###############################################################################
###############################################################################

my $ver = $Random::Simple::VERSION;
printf("Using %s %s\n\n", color('yellow', 'Random::Simple'), color('white', "v" .$ver));

my $x   = Random::Simple::random_bytes(14);
my $len = length($x);
my $str = (unpack("h* ", $x));
print "Got $len random bytes: 0x$str\n\n";

my $min = -20;
my $max = 10;
my @nums;
for (1 .. 9) {
	my $num = Random::Simple::random_int($min, $max);
	push(@nums, $num);
}

my $num_str = join(", ", @nums);
print "Random numbers (inclusive) between $min and $max = $num_str\n\n";

for (1 .. 5) {
	my $x = Random::Simple::random_float();
	print "Float #$_: $x\n";
}

print "\n";

########################################################################
# Undocumented and has potential to change: _rand32() and _rand64()
#
# Note: these functions do *NOT* auto seed, so if you call this as your
# first function call in Random::Simple you will get zero-filled
# results, which is not going to be what you want. All other function
# calls will auto seed if they're the first called function
########################################################################

for (1 .. 5) {
	my $x = Random::Simple::_rand32();
	my $per = sprintf("%0.1f%%", ($x / (2**32 - 1) * 100));

	if ($debug) {
		print "32bit #$_: $x ($per)\n";
	} else {
		print "32bit #$_: $x\n";
	}
}

print "\n";

for (1 .. 5) {
	my $x = Random::Simple::_rand64();
	my $per = sprintf("%0.1f%%", ($x / (2**64 - 1) * 100));

	if ($debug) {
		print "64bit #$_: $x ($per)\n";
	} else {
		print "64bit #$_: $x\n";
	}
}

###############################################################################
###############################################################################

sub trim {
	my ($s) = (@_, $_); # Passed in var, or default to $_
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;

	return $s;
}

# String format: '115', '165_bold', '10_on_140', 'reset', 'on_173', 'red', 'white_on_blue'
sub color {
	my ($str, $txt) = @_;

	# If we're NOT connected to a an interactive terminal don't do color
	if (-t STDOUT == 0) { return $txt; }

	# No string sent in, so we just reset
	if (!length($str) || $str eq 'reset') { return "\e[0m"; }

	# Some predefined colors
	my %color_map = qw(red 160 blue 27 green 34 yellow 226 orange 214 purple 93 white 15 black 0);
	$str =~ s|([A-Za-z]+)|$color_map{$1} // $1|eg;

	# Get foreground/background and any commands
	my ($fc,$cmd) = $str =~ /^(\d{1,3})?_?(\w+)?$/g;
	my ($bc)      = $str =~ /on_(\d{1,3})$/g;

	# Some predefined commands
	my %cmd_map = qw(bold 1 italic 3 underline 4 blink 5 inverse 7);
	my $cmd_num = $cmd_map{$cmd // 0};

	my $ret = '';
	if ($cmd_num)     { $ret .= "\e[${cmd_num}m"; }
	if (defined($fc)) { $ret .= "\e[38;5;${fc}m"; }
	if (defined($bc)) { $ret .= "\e[48;5;${bc}m"; }
	if ($txt)         { $ret .= $txt . "\e[0m";   }

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
	if (eval { require Data::Dump::Color }) {
		*k = sub { Data::Dump::Color::dd(@_) };
	} else {
		require Data::Dumper;
		*k = sub { print Data::Dumper::Dumper(\@_) };
	}

	sub kd {
		k(@_);

		printf("Died at %2\$s line #%3\$s\n",caller());
		exit(15);
	}
}

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4

