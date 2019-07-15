#!/usr/bin/perl

use strict;
use warnings;

our $VERSION = "0.051 - 20190711";

(my $cmd = $0) =~ s{.*/}{};

sub usage {
    my $err = shift and select STDERR;
    print "usage: $cmd [options]\n";
    exit $err;
    } # usage

use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"      => sub { usage (0); },
    "V|version"   => sub { print "$cmd [$VERSION]\n"; exit 0; },

    "v|verbose:1" => \my $opt_v,
    ) or usage (1);

use System::Info qw( si_uname );

my $si = System::Info->new ();
print "-- from methods\n";
printf "Distname             : %s\n", si_uname;
printf "Hostname             : %s\n", $si->host;
printf "Number of CPU's      : %s\n", $si->ncpu;
printf "Processor type       : %s\n", $si->cpu_type;   # short
printf "Processor description: %s\n", $si->cpu;        # long
printf "OS and version       : %s\n", $si->os;

my $sih = System::Info->sysinfo_hash;
print "-- from hash\n";
printf "%-21s: %s\n", $_, $sih->{$_} for sort keys %$sih;
