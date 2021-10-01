#! /usr/bin/env perl
use Test2::V0;
use Mock::Data::Util qw( _dump );
use Mock::Data::Plugin::Net;
use Mock::Data;
sub _flatten;

my $reps= $ENV{GENERATE_COUNT} || 5;

my @tests= (
	ipv4 => [
		[],                                      qr/^127\.\d+\.\d+\.\d+/,
	],
	cidr => [
		[],                                      qr,^127\.\d+\.\d+\.\d+/\d+,,
	],
	macaddr => [
		[],                                      qr/^(?: [0-9a-f]{2} : ){5} [0-9a-f]{2} $/x,
	],
);
my $mock= Mock::Data->new([qw( Net )]);
for (my $i= 0; $i < @tests; $i += 2) {
	my ($generator, $subtests)= @tests[$i, $i+1];
	subtest $generator => sub {
		for (my $j= 0; $j < @$subtests; $j += 2) {
			my ($args, $expected)= @{$subtests}[$j,$j+1];
			my $name= '('.join(',', map _dump, @$args).')';
			for (1 .. $reps) {
				like( $mock->$generator(@$args), $expected, $name );
			}
		}
	};
}

done_testing;
