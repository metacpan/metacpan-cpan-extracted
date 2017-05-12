#!/usr/bin/perl

use warnings;
use strict;

use Socket;
use Benchmark qw(cmpthese);
use Sort::Key;
use Sort::Key::IPv4 qw(ipv4sort ipv4_to_uv);
use Sort::Key::Radix;

$| = 1;
my $n = 100_000;

my @address = map { join ('.', 0, 0, 0, map {int rand 256 } 0..0) } 0..$n;

print "\@address populated\n";

sub gloryhackish {
  my @in = @address;
  my @sorted = map { $_ = inet_ntoa($_) }
    (sort (map {$_ = inet_aton($_)} @in));
}

sub ks {
  my @sorted = Sort::Key::keysort { inet_aton($_) } @address;
}

sub uks {
  my @sorted = Sort::Key::ukeysort(\&ipv4_to_uv, @address);
}

sub ipv4s {
    my @sorted = ipv4sort @address;
}

sub radix {
    # print ".";
    my @sorted = Sort::Key::Radix::ukeysort(\&ipv4_to_uv, @address)
}

cmpthese 10, { # gloryhackish => \&gloryhackish,
               keysort => \&ks,
               ukeysort => \&uks,
               ipv4sort => \&ipv4s,
               radix => \&radix };
