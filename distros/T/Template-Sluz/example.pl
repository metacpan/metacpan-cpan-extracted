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

#print $s->parse_string('Hello {$name}');
print $s->fetch(Template::Sluz::SLUZ_INLINE);

$s->set_delimiters("<", ">");
print $s->parse_string("Hello <\$name>, you are <\$data.age>\n");

###############################################################################
###############################################################################

sub joina {
	my $arr  = shift();
	my $glue = shift();

	my $ret = join($glue, @$arr);

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
Using Template::Sluz {$version}

Hello {$name|uc}

{foreach $colors as $c}
* {$c}
{/foreach}

{$colors|join:"/"}

Literal: {literal}{}{/literal}

Hash: {$data.age} = {$data.color} = {$data.bad|default:"Me"}

Array index #1: {$colors.1}

Substr: {$name|substr:0,3}
