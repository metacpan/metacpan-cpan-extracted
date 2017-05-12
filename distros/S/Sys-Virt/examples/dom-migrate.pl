#!/usr/bin/perl


use strict;
use warnings;

use Sys::Virt;
use Sys::Virt::Domain;

if (int(@ARGV) < 4) {
    die "syntax: $0 URI DOMAIN DEST-URI DISK1 [DISK2 [DISK3 ...]]";
}

my $uri = shift @ARGV;

my $c = Sys::Virt->new(uri => $uri);

my $dom = $c->get_domain_by_name(shift @ARGV);

my $desturi = shift @ARGV;

my @disks = @ARGV;


$dom->migrate_to_uri(
    $desturi, {
	Sys::Virt::Domain::MIGRATE_PARAM_MIGRATE_DISKS => \@disks,
    },
    Sys::Virt::Domain::MIGRATE_PEER2PEER);
