#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use autodie ':default';
use Devel::Confess 'color';
use Capture::Tiny 'capture';
#use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};

sub execute {#($cmd, $return = 'exit', $die = 1) {
	my ($cmd, $return, $die) = @_;
	$return = 'exit' unless defined $return;
	$die    = 1      unless defined $die;
	if ($return !~ m/^(exit|stdout|stderr|all)$/) {
		die "you gave \$return = \"$return\", while this subroutine only accepts ^(exit|stdout|stderr)\$";
	}
	my ($stdout, $stderr, $exit) = capture {
		system( $cmd )
	};
	if (($die == 1) && ($exit != 0)) {
		print STDERR "exit = $exit\n";
		print STDERR "STDOUT = $stdout\n";
		print STDERR "STDERR = $stderr\n";
		die "$cmd\n failed";
	}
	if ($return eq 'exit') {
		return $exit
	} elsif ($return eq 'stderr') {
		chomp $stderr;
		return $stderr
	} elsif ($return eq 'stdout') {
		chomp $stdout;
		return $stdout
	} elsif ($return eq 'all') {
		chomp $stdout;
		chomp $stderr;
		return {
			exit   => $exit, 
			stdout => $stdout, 
			stderr => $stderr
		}
	} else {
		die "$return broke pigeonholes"
	}
	return $stdout
}

foreach my $ver ('5.10.1', '5.42.2') {
	execute("perlbrew use perl-$ver");
}
