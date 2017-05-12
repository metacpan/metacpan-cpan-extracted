#!/usr/bin/perl

use strict;
use warnings;

use Net::OpenSSH::Parallel;
use POSIX ();

my @hosts = qw(localhost 127.0.0.1 192.168.21.1);

my $pssh = Net::OpenSSH::Parallel->new;

my %filter_fh;
for my $host (@hosts) {

    my $pid = open my $out, '|-';
    unless ($pid) {
        defined $pid or die "unable to fork filter process: $!";
        $| = 1;
        while (<>) {
            print "$host: $_";
        }
        POSIX::_exit(0);
    }

    $filter_fh{$host} = $out;

    $pssh->add_host($host, default_stdout_fh => $out);
}

$pssh->push('*', cmd => 'find /');
$pssh->run;

close $_ for values %filter_fh;
