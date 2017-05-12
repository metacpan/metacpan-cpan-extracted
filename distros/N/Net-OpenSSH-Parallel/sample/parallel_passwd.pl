#!/usr/bin/perl

use strict;
use warnings;

use Term::ReadKey;
use Net::OpenSSH::Parallel;
use Expect;
use Getopt::Std;

my $timeout = 10;

open my $tty, "+>", "/dev/tty" or die "unable to open tty";
select $tty;
$| = 1;
select STDOUT;

our ($opt_l);
getopt('l:');

@ARGV or die "Usage:\n  $0 [-l user] host1 host2 host3 ...\n\n";

ReadMode 2, $tty;
print $tty "Old password: ";
my $old = ReadLine 0, $tty;
print $tty "\nNew password: ";
my $new = ReadLine 0, $tty;
print $tty "\nRetype new password: ";
my $new_bis = ReadLine 0, $tty;
print $tty "\n";
ReadMode 0, $tty;

$new eq $new_bis or die "Sorry, passwords do not match\n";

sub answer_passwd {
    my ($expect, $pattern, $pass) = @_;
    $expect->expect($timeout, -re => $pattern) or return;
    $expect->send($pass);
    $expect->expect($timeout, "\n") or return;
    1;
}

sub change_password {
    my ($host, $ssh) = @_;
    my ($pty) = $ssh->open2pty('passwd');
    my $expect = Expect->init($pty);
    $expect->raw_pty(1);
    # $expect->log_user(1);
    if (answer_passwd($expect, 'current.*:', $old)    and
        answer_passwd($expect, 'Enter new.*:', $new)  and
        answer_passwd($expect, 'Retype new.*:', $new) and
        $expect->expect($timeout, "success")) {
        exit(0);
    }
    exit(1);
}

my @ssh_args = (password => $old);
push @ssh_args, (user => $opt_l) if defined $opt_l;

my $pssh = Net::OpenSSH::Parallel->new();
$pssh->add_host($_, @ssh_args) for @ARGV;
$pssh->push('*', parsub => \&change_password);
$pssh->run;

for my $host (@ARGV) {
    if ($pssh->get_error($host)) {
        print "unable to change password for host $host!\n";
    }
    else {
        print "password changed successfully for host $host.\n";
    }
}

