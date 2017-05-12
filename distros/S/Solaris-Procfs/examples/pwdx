#!/usr/local/bin/perl -w

use strict;
use ExtUtils::testlib;
use Solaris::Procfs qw(:procfiles cwd);
use lib '.';

my $pid;
my @pidlist  = (@ARGV ? @ARGV : getpids());

foreach $pid (@pidlist) {

	my $cwd = cwd($pid);

	unless (defined $cwd) {

		warn "$0: no such process: $pid\n";
		next;
	}

	printf ("%d:\t%s\n", $pid,$cwd);
}

