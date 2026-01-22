#!/usr/bin/env perl

package Net::Server::Test;
# Test to ensure NO_IPV6 works properly.
use strict;
use warnings;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok note);
my $IPv4 = "127.0.0.1"; # Should connect to IPv4
my $IPv6 = "::1"; # Should not connect to IPv6
$ENV{NO_IPV6} = 1;
my $env = prepare_test({n_tests => 6, start_port => 20700, n_ports => 1}); # runs three of its own tests
ok(!eval { require Net::Server::Proto; Net::Server::Proto->ipv6_package({}) }, "NO_IPV6 FAILURE! ipv6_package still detected");

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
        my $remote = NetServerTest::client_connect(
            PeerAddr => $IPv6,
            PeerPort => $env->{'ports'}->[0],
            Proto    => 'tcp');
        die "IPv6 connected to [$IPv6] [$env->{'ports'}->[0]] even with NO_IPV6" if $remote;

        ### connect to child using IPv6
        $remote = NetServerTest::client_connect(
            PeerAddr => $IPv4,
            PeerPort => $env->{'ports'}->[0],
            Proto    => 'tcp') || die "Couldn't open sock to [$IPv4] [$env->{'ports'}->[0]]: $!";

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
                ipv  => "*",
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
