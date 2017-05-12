#!perl -w

use strict;
use Benchmark qw(:all);

use Scalar::Alias;

sub aliased{
	my alias $x = shift;
	return;
}
sub no_aliased{
	my $x = shift;
	return;
}

print "For integer\n";
my @integers = ((42) x 10);
cmpthese -1 => {
	alias => sub{
		for my $i(@integers){
			aliased($i);
		}
	},
	assign => sub{
		for my $i(@integers){
			no_aliased($i);
		}
	},
};

print "For string\n";
my @strings = (('foo') x 10);
cmpthese -1 => {
	alias => sub{
		for my $i(@strings){
			aliased($i);
		}
	},
	assign => sub{
		for my $i(@strings){
			no_aliased($i);
		}
	},
};

print "For object reference\n";
my @refs = ((bless{}) x 10);
cmpthese -1 => {
	alias => sub{
		for my $i(@refs){
			aliased($i);
		}
	},
	assign => sub{
		for my $i(@refs){
			no_aliased($i);
		}
	},
};
