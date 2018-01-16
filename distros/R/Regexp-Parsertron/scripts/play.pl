#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Regexp::Parsertron;

use Try::Tiny;

# -----------

my($s)	= 'foofoo';
my($re)	= qr/(?:(?<n>foo)|(?<n>bar))\k<n>/;

print "String: $s. Regexp: $re. ";

if ($s =~ $re)
{
	say "Match. ";
}
else
{
	say "Does not match. ";
}

say '-' x 50;

my($parser)	= Regexp::Parsertron -> new(verbose => 0);
my(%input)	=
(
	 1 => q!(?:(?<n>foo)|(?<n>bar))\k<n>!,
	 2 => q!/foofoo/!,
	 3 => q!'(*)b'i!,
	 4 => q!(?|(a))!,
	 5 => q!(?^u:'()ef'i)!,
	 6 => q!(?^u:'(.*)c(.*)'i)!,
);

my($as_string);
my($error_str);
my($found);
my($result, %re);

for my $key (sort keys %input)
{
	say "Case $key: ";

	$error_str	= '';
	$s			= $input{$key};

	try
	{
		$re	= qr/$s/;
	}
	catch
	{
		$error_str = "Perl error for $s: $_"; # Do it this way because continue and next don't work inside try.

		print $error_str;
	};

	next if ($error_str);

	$result		= $parser -> parse(re => $s);
	$error_str	= $parser -> error_str;

	if ($error_str)
	{
		say "Marpa error: $error_str";
	}
	else
	{
		$parser -> print_raw_tree;

		$as_string	= $parser -> as_string;
		$re{$key}	= $as_string;

		say "result: $result (0 is success). as_string: $as_string";

		for my $target ('foo', '?')
		{
			$found = $parser -> find($target);

			say "uids of nodes whose text matches $target: ", join(', ', @$found);
		}
	}

	$parser -> reset;
}

say '-' x 50;
