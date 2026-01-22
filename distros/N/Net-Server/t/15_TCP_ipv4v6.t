#!/usr/bin/env perl

package Net::Server::Test;
# Test to ensure v4v6 listens on both IPv4 and IPv6 interfaces.
use strict;
use warnings;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok note skip_without_ipv6);
skip_without_ipv6;
my $IPv4 = "127.0.0.1"; # Should connect to IPv4
my $IPv6 = "::1"; # Should also connect to IPv6
my $env = prepare_test({n_tests => 5, start_port => 20700, n_ports => 1}); # runs three of its own tests

use_ok('Net::Server');
@Net::Server::Test::ISA = qw(Net::Server);

sub accept {
    $env->{'signal_ready_to_test'}->();
    alarm($env->{'timeout'});
    return shift->SUPER::accept(@_);
}

my $ok = eval {
    local $SIG{'ALRM'} = sub { die "Timeout\n" };
    alarm $env->{'timeout'};
    my $ppid = $$;
    my $pid = fork;
    die "Trouble forking: $!" if ! defined $pid;

    ### parent does the client
    if ($pid) {
        $env->{'block_until_ready_to_test'}->();

        ### connect to child using IPv4
        my $remote = Net::Server::Proto->ipv6_package->new(
            PeerAddr => $IPv4,
            PeerPort => $env->{'ports'}->[0],
            Proto    => 'tcp');
        die "IPv4 connection failed to [$IPv4] [$env->{'ports'}->[0]]" if !$remote;

        ### connect to child using IPv6
        $remote = Net::Server::Proto->ipv6_package->new(
            PeerAddr => $IPv6,
            PeerPort => $env->{'ports'}->[0],
            Proto    => 'tcp') || die "Couldn't open sock to [$IPv6] [$env->{'ports'}->[0]]: $!";

        my $line = <$remote>;
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        print $remote "exit\n";
        return 1;

    ### child does the server
    } else {
        eval {
            open STDERR, ">", "/dev/null";
            local $SIG{ALRM} = sub { die "Timeout" };
            alarm(5);
            Net::Server::Test->run(
                port => "$env->{'ports'}->[0]/tcp",
                host => "*",
                ipv  => "v4v6",
                background => 0,
                setsid => 0,
            );
        } || do {
            note("Trouble running server: $@");
            kill(9, $ppid) && ok(0, "Failed during run of server");
        };
        exit;
    }
    alarm(0);
    return 1;
};
alarm(0);
ok($ok, "Got the correct output from the server") || note("Error: $@");
