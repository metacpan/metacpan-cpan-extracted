#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';

my $host = shift @ARGV;
my $local_iface = 'lxcbr0';
my $remote_iface = 'eth0';

#my $size = 512 * 1024 * 1024;
my $size = 16 * 1024 * 1024;
my $dd_bs = 16 * 1024;
my $dd_count = int($size / $dd_bs);
my $cmd = "dd bs=$dd_bs count=$dd_count if=/dev/zero 2>/dev/null";
my @openssh_windows = map "OpenSSH $_", 1..3;
#$cmd = "cat /home/salva/Downloads/Renta2014_unix_1_25.sh";

#my @delays  = (0, map 2**$_, 4, 6, 7, 8, 9);
#my @windows = (0.25, 0.5, 1, 2, 4);

my @delays = (0, map int 4 * 1.5 ** $_, 0..8);
my @windows = (2, 2, 2, 2, 2, 2, 2, 2);

use Time::HiRes qw(time);
use Net::SSH::Any;

$Net::SSH::Any::Backend::Net_SSH2::stdout_buffer_size = 100;

my $ssh2 = Net::SSH::Any->new($host,
			      strict_host_key_checking => 0,
			      known_hosts_path => '/dev/null',
			      key_path => scalar(<~/.ssh/id_rsa>),
                              batch_mode => 1,
			      compress => 0,
			      backends => 'Net_SSH2');
$ssh2->error and die "unable to connect using libssh2: @{$ssh2->{backend_log}}";

my $openssh = Net::SSH::Any->new($host,
                                 strict_host_key_checking => 0,
                                 known_hosts_path => '/dev/null',
                                 key_path => scalar(<~/.ssh/id_rsa>),
                                 batch_mode => 1,
                                 compress => 0,
                                 backends => 'Net_OpenSSH');
$openssh->error and die "unable to connect using OpenSSH: @{$openssh->{backend_log}}";

my %summary;

$| = 1;

sub test {
    my ($ssh, $delay, $window) = @_;
    my %opts = (stdout_file => '/dev/null');
    my ($window_name);
    if ($window =~ /^[\d\.]+$/) {
	$opts{_window_size} = $window * 1024 * 1024;
	$window_name = "${window}MB";
    }
    else {
	$window_name = $window;
    }
    my $time0 = time;
    $ssh->system(\%opts, $cmd);
    my $time1 = time;
    my $dt = $time1 - $time0;
    my $speed = $size / $dt / 1024 / 1024; # MB/s
    printf "delay: %dms, window: %s, time: %.2fs, speed: %.2fMB/s\n", $delay, $window_name, $dt, $speed;
    $summary{"$window,$delay"} = $speed;
}

for my $delay (@delays) {
    system "tc qdisc del dev $local_iface root netem delay 0ms 2>/dev/null";
    $ssh2->system("tc qdisc del dev $remote_iface root netem delay 0ms 2>/dev/null");
    $ssh2->system("tc qdisc add dev $remote_iface root netem delay ${delay}ms");
    system "tc qdisc add dev $local_iface root netem delay ${delay}ms";
    test($ssh2, $delay, $_) for @windows;
    test($openssh, $delay, $_) for @openssh_windows;
    system "tc qdisc del dev $local_iface root netem delay 0ms 2>/dev/null";
    $ssh2->system("tc qdisc del dev $remote_iface root netem delay ${delay}ms");
    say "";
}

END {
    say join(', ', 'windows', @windows, @openssh_windows);
    for my $delay (@delays) {
	say join(', ', $delay, map $summary{"$_,$delay"}, @windows, @openssh_windows);
    }
}
