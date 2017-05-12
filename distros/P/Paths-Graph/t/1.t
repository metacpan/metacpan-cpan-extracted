#!/usr/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 4;
BEGIN { 
	use_ok('Paths::Graph'); 
	require_ok('Paths::Graph'); 
}

ok(test1());
ok(test2());


# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub test1 {
	my %graph = (A => {B=>1});
	use Paths::Graph;
	my $obj = Paths::Graph->new(-origin=>"A",-destiny=>"B",-graph=>\%graph);
	my @paths = $obj->shortest_path();
	print join ("->" , @{$_}) . "\n" . $obj->get_path_cost(@{$_}) for @paths;
	print "\n";
	return 1;
}

sub test2 {
	my %graph = (A => {B=>1});
	use Paths::Graph;
	my $obj = Paths::Graph->new(-origin=>"A",-destiny=>"B",-graph=>\%graph,-sub=>\&test);
	$obj->free_path_event();
	return 1;
}
sub test {my ($self,@n) = @_;print join("->",@n) . "\n";}





