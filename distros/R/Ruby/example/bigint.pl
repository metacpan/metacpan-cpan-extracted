#!perl

use warnings;
use strict;

use Benchmark qw(:hireswallclock timethese cmpthese);


my $s = Benchmark->new;

require  Math::BigInt;

print "require Math::BigInt;\n\t", Benchmark->new->timediff($s)->timestr, "\n";

$s = Benchmark->new;

require Ruby;

print "require Ruby;\n\t", Benchmark->new->timediff($s)->timestr, "\n";

print "\n";


cmpthese timethese 0 => {
	perlmul => q{
		use bigint;

		my $i = 1;

		for(1 .. 100){ $i *= 2; }
	},
	perladd => q{
		use bigint;

		my $i = 2**64;

		for(1 .. 100){ $i += 100_000; }
	},


	rubymul => q{
		use Ruby -literal;

		my $i = 1;

		for(1 .. 100){ $i *= 2; }
	},
	rubyadd => q{
		use Ruby -literal;

		my $i = 2**64;

		for(1 .. 100){ $i += 100_000; }
	},
};
