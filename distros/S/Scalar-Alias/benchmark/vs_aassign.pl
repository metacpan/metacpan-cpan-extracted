#!perl -w

use strict;
use Benchmark qw(:all);

use Scalar::Alias;

print "Benchmark; list alias vs. list assignment\n";

print "For integer\n";
my @integers = ((42) x 100);
cmpthese -1 => {
	alias => sub{
		for my $i(@integers){
			my alias($x) = $i;
			my alias($y) = $i;
			my alias($z) = $i;
		}
	},
	assign => sub{
		for my $i(@integers){
			my($x) = $i;
			my($y) = $i;
			my($z) = $i;
		}
	},
};

print "For string\n";
my @strings = (('foobar') x 100);
cmpthese -1 => {
	alias => sub{
		for my $i(@strings){
			my alias($x) = $i;
			my alias($y) = $i;
			my alias($z) = $i;
		}
	},
	assign => sub{
		for my $i(@strings){
			my($x) = $i;
			my($y) = $i;
			my($z) = $i;
		}
	},
};

print "For object reference\n";
my @refs = ((bless{}) x 100);
cmpthese -1 => {
	alias => sub{
		for my $i(@refs){
			my alias($x) = $i;
			my alias($y) = $i;
			my alias($z) = $i;
		}
	},
	assign => sub{
		for my $i(@refs){
			my($x) = $i;
			my($y) = $i;
			my($z) = $i;
		}
	},
};
