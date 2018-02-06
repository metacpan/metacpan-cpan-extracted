#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Regexp::Parsertron;

use Try::Tiny;

# -----------

my($parser)	= Regexp::Parsertron -> new(verbose => 2);
my(%stats)	= (success => 0, total => 0);
my(%input)	=
(
	1 => q!(?|(.{2,4}))!,
	2 => q!Perl|JavaScript|(?:Flub|BCPL)!,
	3 => q!(?^i:Perl|JavaScript|(?:Flub|BCPL))!,
	4 => q!(?a:b)!,
	5 => q!(?:(?<n>foo)|(?<n>bar))!,
	6 => q!(?:(?<n2>foo)|(?<n2>bar))\k<n2>!,
	7 => q#(?(?!a)a|b)#,
);

my($as_string);
my($error_str);
my($found);
my($re, $result, %re);
my($s);

for my $key (sort keys %input)
{
	$stats{total}++;

	print "Case $key: ";

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

	try
	{
		$result		= $parser -> parse(re => $s);
		$as_string	= $parser -> as_string;
		$re{$key}	= $as_string;

		$stats{success}++ if ($result == 0);

		for my $target ('?')
		{
			$found = $parser -> find($target);

			say "uids of nodes whose text matches =>$target<=: ", join(', ', @$found);
		}

		$result = $parser -> validate;

		say "Calling validate() on $s: $result (0 is success)";
		say "Case: $key. as_string: $as_string. result: $result (0 is success)";
	}
	catch
	{
		say $_;
	};

	say '-' x 100;

	$parser -> reset;
}

print "Statistics: ";
print "$_: $stats{$_}. " for (sort keys %stats);
say '';
