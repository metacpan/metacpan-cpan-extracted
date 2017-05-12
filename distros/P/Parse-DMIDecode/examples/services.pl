#!/usr/bin/perl -wT

use strict;
use DBI qw();

my %service;
open(SER,'<','/etc/services') || die "Unable to open file '/etc/services': $!";
while (local $_ = <SER>) {
	next if /^\s*#/ || /^\s*$/;
	my $desc;
	if (/#\s*(.+)\s*$/) {
		$desc = $1;
		s/#.*$//;
	}
	my ($service,$port,@aliases) = split(/\s+/,$_);
	$service{$port} = {
			name => $service,
			aliases => \@aliases,
			desc => $desc,
		};
}
close(SER) || die "Unable to close file '/etc/services': $!";

my $dbh = DBI->connect('DBI:mysql:machinedb:localhost','machinedb_update','a8fc0ebf41ed43eb2686fcec2291c071');
my $sth = $dbh->prepare(qq{
	SELECT hostname,data
		FROM probe
		NATURAL JOIN machine
		NATURAL JOIN host
		WHERE probe = ? ORDER BY hostname
	});

$sth->execute('netstat');
my @cols = qw(proto recvq sendq local foreign state process);

while (my ($hostname,$data) = $sth->fetchrow_array) {
	print "$hostname\n";
	for (split(/\n/,$data)) {
		next unless /[:\*\d]/;
		my %data;
		@data{@cols} = split(/\s+/,$_);
		if ($data{proto} =~ /^tcp/ && $data{state} eq 'LISTEN') {
			($data{port}) = $data{local} =~ /:([\d\*]+)$/;
			my $desc = '';
			if (exists $service{"$data{port}/tcp"}) {
				$desc = $service{"$data{port}/tcp"}->{desc} ||
					$service{"$data{port}/tcp"}->{name} || '';
			}
			printf("\t%s\t%s\n",$data{port},$desc);
		}
	}
	print "\n";
}

$sth->finish;
$dbh->disconnect;



