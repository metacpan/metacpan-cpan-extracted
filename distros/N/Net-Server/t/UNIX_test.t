#!/usr/bin/perl

package Net::Server::Test;
use strict;
use POSIX qw(tmpnam);
use English qw($UID $GID);
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok diag skip);
my $env = prepare_test({n_tests => 5, start_port => 20800, n_ports => 1}); # runs three of its own tests

if ($^O eq 'MSWin32') {
    SKIP: { skip("UNIX Sockets will not work on Win32", 2) };
    exit;
}

use_ok('Net::Server');
@Net::Server::Test::ISA = qw(Net::Server);

sub accept {
    $env->{'signal_ready_to_test'}->();
    return shift->SUPER::accept(@_);
}

my $socket_file = tmpnam; # must do before fork
my $ok = eval {
    local $SIG{'ALRM'} = sub { die "Timeout\n" };
    alarm $env->{'timeout'};
    my $ppid = $$;
    my $pid = fork;
    die "Trouble forking: $!" if ! defined $pid;

    ### parent does the client
    if ($pid) {
        $env->{'block_until_ready_to_test'}->();

        ### connect to child under unix
        my $remote = IO::Socket::UNIX->new(Peer => $socket_file);
        die "No socket returned [$!]" if ! defined $remote;
        my $line = <$remote>;
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        print $remote "quite\n";

        ### connect to child under tcp
        $remote = NetServerTest::client_connect(
            PeerAddr => $env->{'hostname'},
            PeerPort => $env->{'ports'}->[0],
            Proto    => 'tcp') || die "Couldn't open to sock: $!";

        $line = <$remote>;
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        print $remote "exit\n";
        return 1;

    ### child does the server
    } else {
        eval {
            close STDERR;
            Net::Server::Test->run(
                port  => "$env->{'ports'}->[0]/tcp",
                port  => "$socket_file|unix",
                user  => $UID, # user  accepts id as well
                group => $GID, # group accepts id as well
                host  => $env->{'hostname'},
                ipv   => $env->{'ipv'},
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
