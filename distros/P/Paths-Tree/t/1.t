#!/usr/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 3;
BEGIN { 
	use_ok('Paths::Tree'); 
	require_ok('Paths::Tree'); 
}

ok(test1());

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub test1 {
	my %tree = (
			2 => [3,"HELLO"],
			HELLO => ["YOU",WORLD],
			"RAIZ" => [1,2],
	);
	sub show {
		my ($child , $level) = @_;
		if ($level) {
			print "_" foreach 1 .. $level; 
			print "$child \n";
		}
	}
	use Paths::Tree;
	my $n = Paths::Tree->new(-origin=>"RAIZ",-tree=>\%tree,-sub=>\&show);
	$n->tree();
	return 1

}

