#!/usr/bin/perl


my %tree = (
		2 => [3,"HELLO"],
		HELLO => ["YOU",WORLD],
		"RAIZ" => [1,2],
);

sub show {
	my ($child , $level) = @_;
	print "    " for 0 .. $level; 
	print "$child \n";
}

use Paths::Tree;

my $obj = Paths::Tree->new(-origin=>"RAIZ",-tree=>\%tree,-sub=>\&show);

$obj->tree();


