#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use Template::Sluz;

###############################################################################
###############################################################################

my $s = Template::Sluz->new();

#print joina(['one', 'two', 'three'], "-");
#exit;

$s->assign('name'   , "Jason");
$s->assign('colors' , ['red','green', 'blue']);
$s->assign('data'   , { color => 'red', animal => 'kitten', age => 39 });
$s->assign('version', $Template::Sluz::VERSION);
$s->assign('color_white', color('bold_white'));
$s->assign('color_yellow', color(228));
$s->assign('color_reset', color('reset'));

#print $s->parse_string('Hello {$name}');
print $s->fetch(Template::Sluz::SLUZ_INLINE);

print $s->parse_string('HTML: <div>Name: {$name} / Colors: {$colors|join:", "}</div>') . "\n";

$s->set_delimiters("<", ">");
print $s->parse_string('JSON: {"name": "<$name>", "animal": "<$data.animal>"}') . "\n";

###############################################################################
###############################################################################

sub joina {
	my $arr  = shift();
	my $glue = shift();

	my $ret = join($glue, @$arr);

	return $ret;
}

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

__DATA__
Using {$color_white}Template::Sluz{$color_reset} {$color_yellow}{$version}{$color_reset}

Hello {$name|uc}

{foreach $colors as $c}
* {$c}
{/foreach}

Literal: {literal}function foo() { ... }{/literal}

Array index #1: {$colors.1}

