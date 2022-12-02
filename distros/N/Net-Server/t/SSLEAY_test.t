#!/usr/bin/env perl

package Net::Server::Test;
use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok note skip);
my $env = prepare_test({n_tests => 4, start_port => 20200, n_ports => 2}); # runs three of its own tests

if (! eval { require Net::SSLeay }
   ) {
  SKIP: { skip("Cannot load Net::SSleay libraries to test Socket SSL server: $@", 1); };
    exit;
}
if (! eval { require Net::Server::Proto::SSLEAY }) {
    note "Cannot load SSLEAY library on this platform: $@";
  SKIP: { skip("Skipping tests on this platform", 1); };
    exit;
}

require Net::Server;
@Net::Server::Test::ISA = qw(Net::Server);

sub accept {
    my $self = shift;
    exit if $^O eq 'MSWin32' && $self->{'__one_accept_only'}++;
    $env->{'signal_ready_to_test'}->();
    return $self->SUPER::accept(@_);
}

sub process_request {
    my $self = shift;
    my $client = $self->{'server'}->{'client'};
    return $self->SUPER::process_request if $client->NS_port == $env->{'ports'}->[1];
    my $offset = 0;
    my $total = 0;
    my $buf;

    # Wait data
    my $vec = '';
    vec($vec, $client->fileno, 1) = 1;

    until ($buf) {
        select($vec, undef, undef, undef);
        $client->sysread(\$buf, 100, $total);
    }

    select(undef, $vec, undef, undef);

    $client->syswrite($buf);

    $self->server_close;
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

        my $remote = NetServerTest::client_connect(PeerAddr => $env->{'hostname'}, PeerPort => $env->{'ports'}->[1]) || die "Couldn't open child to sock: $!";

        my $ctx = Net::SSLeay::CTX_new()
            or Net::SSLeay::die_now("Failed to create SSL_CTX $!");
        Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL)
            and Net::SSLeay::die_if_ssl_error("ssl ctx set options");
        my $ssl = Net::SSLeay::new($ctx)
            or Net::SSLeay::die_now("Failed to create SSL $!");
        Net::SSLeay::set_fd($ssl, $remote->fileno);
        Net::SSLeay::connect($ssl);
        my $line = Net::SSLeay::read($ssl);
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        note $line;
        Net::SSLeay::write($ssl, "quit\n");
        my $line2 = Net::SSLeay::read($ssl);
        note $line2;


        $remote = NetServerTest::client_connect(PeerAddr => $env->{'hostname'}, PeerPort => $env->{'ports'}->[0]) || die "Couldn't open child to sock: $!";

        $ctx = Net::SSLeay::CTX_new()
            or Net::SSLeay::die_now("Failed to create SSL_CTX $!");
        Net::SSLeay::CTX_set_options($ctx, &Net::SSLeay::OP_ALL)
            and Net::SSLeay::die_if_ssl_error("ssl ctx set options");
        $ssl = Net::SSLeay::new($ctx)
            or Net::SSLeay::die_now("Failed to create SSL $!");

        Net::SSLeay::set_fd($ssl, $remote->fileno);
        Net::SSLeay::connect($ssl);

        Net::SSLeay::write($ssl, "foo bar");
        my $res = Net::SSLeay::read($ssl);
        return $res eq "foo bar";

    ### child does the server
    } else {
        eval {
            alarm $env->{'timeout'};
            close STDERR;
            Net::Server::Test->run(
                host  => $env->{'hostname'},
                port  => $env->{'ports'},
                ipv   => $env->{'ipv'},
                proto => 'ssleay',
                background => 0,
                setsid => 0,
                SSL_cert_file => "$Bin/self_signed.crt",
                SSL_key_file  => "$Bin/self_signed.key",
                );
        } || do {
            note("Trouble running server: $@");
            kill(9, $ppid) && ok(0, "Failed during run of server");
        };
        exit;
    }
    alarm(0);
};
alarm(0);
ok($ok, "Got the correct output from the server") || note("Error: $@");
