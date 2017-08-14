#!/usr/bin/env perl

package Net::Server::Test;
use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok diag);
my $env = prepare_test({n_tests => 5, start_port => 20500, n_ports => 2}); # runs three of its own tests

use_ok('Net::Server::PreForkSimple');
@Net::Server::Test::ISA = qw(Net::Server::PreForkSimple);


sub accept {
    $env->{'signal_ready_to_test'}->();
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
        local $SIG{'ALRM'} = sub { die "Timed out waiting for server\n" };
        alarm $env->{'timeout'};

        $env->{'block_until_ready_to_test'}->();

        my $remote = NetServerTest::client_connect(PeerAddr => $env->{'hostname'}, PeerPort => $env->{'ports'}->[0]) || die "Couldn't open child to sock: $!";
        my $line = <$remote>;
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        print $remote "quit\n";

        $remote = NetServerTest::client_connect(PeerAddr => $env->{'hostname'}, PeerPort => $env->{'ports'}->[1]) || die "Couldn't open child to sock: $!";
        $line = <$remote>;
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        print $remote "exit\n";

        alarm 0;
        return 1;

    ### child does the server
    } else {
        eval {
            alarm $env->{'timeout'};
            close STDERR;
            Net::Server::Test->run(
                port => $env->{'ports'}->[0],
                port => "$env->{'hostname'}:$env->{'ports'}->[1]",
                host => $env->{'hostname'},
                ipv  => $env->{'ipv'},
                max_servers  => 2,
                max_requests => 2,
                background => 0,
                setsid => 0,
            );
        } || do {
            diag("Trouble running server: $@");
            kill(9, $ppid) && ok(0, "Failed during run of server");
        };
        exit;
    }
    alarm(0);
};
alarm(0);
ok($ok, "Got the correct output from the server") || diag("Error: $@");
