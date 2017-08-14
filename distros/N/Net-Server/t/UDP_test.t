#!/usr/bin/env perl

package Net::Server::Test;
use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok diag);
my $env = prepare_test({n_tests => 5, start_port => 20700, n_ports => 2}); # runs three of its own tests

use_ok('Net::Server');
@Net::Server::Test::ISA = qw(Net::Server);

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
        $env->{'block_until_ready_to_test'}->();

        ### connect to child under udp
        my $remote = NetServerTest::client_connect(
            PeerAddr => $env->{'hostname'},
            PeerPort => $env->{'ports'}->[0],
            Proto    => 'udp');

        ### send a packet, get a packet
        $remote->send("Are you there?",0);
        my $data = undef;
        $remote->recv($data, 4096, 0);
        die "No data returned" if ! defined $data;
        die "Didn't get the data we wanted" if $data !~ /Are you there/;

        ### connect to child under tcp
        $remote = NetServerTest::client_connect(
            PeerAddr => $env->{'hostname'},
            PeerPort => $env->{'ports'}->[0],
            Proto    => 'tcp') || die "Couldn't open to sock: $!";

        my $line = <$remote>;
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        print $remote "exit\n";
        return 1;

    ### child does the server
    } else {
        eval {
            close STDERR;
            Net::Server::Test->run(
                port => "$env->{'ports'}->[0]/tcp",
                port => "$env->{'ports'}->[0]/udp",
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
    alarm(0);
};
alarm(0);
ok($ok, "Got the correct output from the server") || diag("Error: $@");
