#!/usr/bin/env perl

package Net::Server::Test;
use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok note);
my $env = prepare_test({n_tests => 5, start_port => 20200, n_ports => 1, threads => 1}); # runs four of its own tests

use_ok('Net::Server::Thread');
@Net::Server::Test::ISA = qw(Net::Server::Thread);

sub accept {
    my $self = shift;
    exit if $^O eq 'MSWin32' && $self->{'__one_accept_only'}++;
    $env->{'signal_ready_to_test'}->();
    return $self->SUPER::accept(@_);
}

my $ok = eval {
    local $SIG{'ALRM'} = sub { die "Timeout\n" };
    alarm $env->{'timeout'};

    ### child does the server
    threads->create(sub {
        eval {
            alarm $env->{'timeout'};
            close STDERR;
            Net::Server::Test->run(
                port => $env->{'ports'}->[0],
                host => $env->{'hostname'},
                ipv  => $env->{'ipv'},
                background => 0,
                setsid => 0,
            );
        } || do {
            note("Trouble running server: $@");
            ok(0, "Failed during run of server");
            exit;
        };
        threads->exit(0);
    })->detach;

    # parent is the client
    $env->{'block_until_ready_to_test'}->();

    my $remote = NetServerTest::client_connect(PeerAddr => $env->{'hostname'}, PeerPort => $env->{'ports'}->[0]) || die "Couldn't open child to sock: $!";
    my $line = <$remote>;
    die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
    print $remote "exit\n";
    alarm(0);
    return 1;
};
alarm(0);
ok($ok, "Got the correct output from the server") || note("Error: $@");
