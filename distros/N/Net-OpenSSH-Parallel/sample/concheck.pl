#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';

use Net::OpenSSH::Parallel;
use Getopt::Long;

my ($login, $password, $file, $verbose);
my $retries = 1;
my $timeout = 10;
GetOptions( "login|l=s"               => \$login,
            "password|passwd|pwd|p=s" => \$password,
            "file|f=s"                => \$file,
            "retries|r=i"             => \$retries,
            "timeout|t=i"             => \$timeout,
            "verbose|v"               => \$verbose);

my @hosts = @ARGV;

# read hosts from file when "file" option is given.
if (defined $file) {
    open my $fh, '<', $file or die "unable to open $file: $!";
    while (<$fh>) {
        next if /^\s*(?:#.*)$/;
        chomp;
        push @hosts, $_;
    }
    close $fh or die "unable to read $file: $!";
}

my $pssh = Net::OpenSSH::Parallel->new;
$pssh->add_host($_, user => $login, password => $password,
                reconnections => $retries,
                master_stderr_discard => 1,
                master_opts => ["-oConnectTimeout=$timeout"]) for @hosts;
$pssh->push('*', 'connect');
$pssh->run;

for (@hosts) {
    my $error = $pssh->get_error($_);
    if ($error) {
        say "Connection to host $_ failed: $error" if $verbose;
        next;
    }
    say "Connection to host $_ succeeded!";
}
