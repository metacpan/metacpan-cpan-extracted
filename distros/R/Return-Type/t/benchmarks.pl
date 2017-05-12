#!/usr/bin/env perl

use strict;
use warnings;
use Benchmark::Report::GitHub;

{
	package Local::Bench;
	use Types::Standard qw(Int);
	use Return::Type;
	sub example1                  { 42 };
	sub example2 :ReturnType(Int) { 42 };
}

my $gh = Benchmark::Report::GitHub->new_from_env;

$gh->add_benchmark(
	'Simple benchmark', -1, {
		raw_sub      => q[ my $x = Local::Bench::example1() ],
		type_checked => q[ my $x = Local::Bench::example2() ],
	},
);

print $gh->publish, "\n";
