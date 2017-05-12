#!/usr/local/bin/perl -w 

$| = 1;

print "1..4\n";

use Proc::Forkfunc;

forkfunc(sub { exit 1} );

&wok(1);

forkfunc(sub { exit $_[0] }, 2);

&wok(2);

forkfunc(\&pok3);

&wok(3);

forkfunc(\&pok, 4);

&wok(4);

sub pok3
{
	exit 3;
}

sub pok
{
	exit $_[0];
}

sub wok
{
	my ($ws) = @_;

	wait();
	my $st = $? >> 8;

	print($st == $ws ? "ok $ws\n" : "not ok $ws\n");
}
