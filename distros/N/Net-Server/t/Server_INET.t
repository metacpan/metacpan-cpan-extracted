#!/usr/bin/perl

package Net::Server::Test;
use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok diag);
my $env = prepare_test({n_tests => 5, start_port => 20300, n_ports => 1}); # runs three of its own tests

use_ok('Net::Server::INET');
@Net::Server::Test::ISA = qw(Net::Server::INET);

my $ok = eval {
    local $SIG{'ALRM'} = sub { die "Timeout\n" };
    alarm $env->{'timeout'};
    my $ppid = $$;
    my $pid = fork;
    die "Trouble forking: $!" if ! defined $pid;

    ### parent does the client
    if ($pid) {
        $env->{'block_until_ready_to_test'}->();
        my $remote = NetServerTest::client_connect(PeerAddr => $env->{'hostname'}, PeerPort => $env->{'ports'}->[0]) || die "Couldn't open child to sock: $!";
        my $line = <$remote>;
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        print $remote "exit\n";
        return 1;

    ### child does the server
    } else {
        eval {
            alarm $env->{'timeout'};
            # pretend we're inetd
            my $sock = NetServerTest::client_connect( # not really a client - client_connect is a raw passthrough to IO::Socket::INET->new
                LocalAddr => $env->{'hostname'},
                LocalPort => $env->{'ports'}->[0],
                Listen    => 5,
                ReuseAddr => 1,
                Reuse => 1,
            ) || die "Couldn't setup server: $!";
            $env->{'signal_ready_to_test'}->();
            my $client = $sock->accept || die "Couldn't accept";
            # map these to look like inetd
            local *STDIN  = \*{ $client };
            local *STDOUT = \*{ $client };
            close STDERR;
            Net::Server::Test->run(
                port => $env->{'ports'}->[0],
                host => $env->{'hostname'},
                ipv  => $env->{'ipv'},
                background => 0,
                setsid => 0,
            );
        } || do {
            diag("Trouble running server: $@");
            kill(9, $ppid) && ok(0, "Failed during run of server");
        };
        exit;
    }
    alarm 0;
};
alarm 0;
ok($ok, "Got the correct output from the server") || diag("Error: $@");
