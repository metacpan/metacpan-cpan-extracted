#!/usr/bin/env perl

package Net::Server::Test;
use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok note);
my $env = prepare_test({n_tests => 5, start_port => 20208, n_ports => 1}); # runs three of its own tests

use_ok('Net::Server::PSGI');
@Net::Server::Test::ISA = qw(Net::Server::PSGI);


sub accept {
    my $self = shift;
    exit if $^O eq 'MSWin32' && $self->{'__one_accept_only'}++;
    $env->{'signal_ready_to_test'}->();
    return $self->SUPER::accept(@_);
}

sub done { 1 } # force exit after first request

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

        print $remote "GET / HTTP/1.0\nFoo: bar\n\n";

        ### sample a line
        my @lines = <$remote>;
        print map {s/\s*$//; "# $_\n"} @lines;
        die "Didn't get a correct http response: ($lines[0])" if !@lines || $lines[0] !~ m{^HTTP/1.0};
        return 1;

    ### child does the server
    } else {
        eval {
            alarm $env->{'timeout'};
            open STDERR, ">", "/dev/null";
            Net::Server::Test->run(
                port => $env->{'ports'}->[0],
                host => $env->{'hostname'},
                ipv  => $env->{'ipv'},
                server_type => 'Single',
                background => 0,
                setsid => 0,
            );
        } || do {
            note("Trouble running server: $@");
            kill(9, $ppid) && ok(0, "Failed during run of server");
        };
        alarm(0);
        exit;
    }
    alarm(0);
};
alarm(0);
ok($ok, "Got the correct output from the server") || note("Error: $@");
