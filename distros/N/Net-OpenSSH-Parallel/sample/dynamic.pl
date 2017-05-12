#!/usr/bin/perl

# this example shows how task can be pushed dynamically

use strict;
use warnings;

use Net::OpenSSH::Parallel;
use Net::OpenSSH::Parallel::Constants qw(OSSH_ON_ERROR_IGNORE);
# $Net::OpenSSH::Parallel::debug = -1;

my @cmds = map "echo running task $_ in host %LABEL% && sleep ".int(1 +log ($_)), 1..100;

my $pssh = Net::OpenSSH::Parallel->new(on_error => \&on_error, workers => 100, connections => 200);

my @hosts = @ARGV;
my %seen;
for my $host (@ARGV) {
    my $label = $host;
    # this code is just to allow me to run "dynamic.pl localhost localhost localhost ..."
    if ($seen{$host}++) {
        $label .= "-$seen{$host}";
    }
    $pssh->add_host($label, $host);
}


sub feed_me {
    my ($pssh, $label) = @_;
    if (defined(my $cmd = shift @cmds)) {
        warn "pushing cmd into host $label: $cmd\n";
        $cmd .= ' && false' if rand(1) > 0.9; # force some random errors just to see how they are handled!
        $pssh->push($label, cmd => $cmd);
        $pssh->push($label, sub => \&feed_me);
    }
    1;
}

my @failed;
sub on_error {
    my ($pssh, $label, $error, $task) = @_;
    warn "execution on host $label of task $task->[2] failed: $error\n";
    push @failed, $task->[2];
    return OSSH_ON_ERROR_IGNORE
}

$pssh->push('*', sub => \&feed_me);
$pssh->run;

if (@failed) {
    warn "The following tasks have failed:\n";
    warn "  $_\n" for @failed;
}
