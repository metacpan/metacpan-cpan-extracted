#!/usr/bin/env perl

package Net::Server::Test;
use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok use_ok diag skip);
my $env = prepare_test({n_tests => 5, start_port => 20200, n_ports => 1});

if (! eval{ require IO::Multiplex; }) {
    diag("Error loading IO::Multiplex: $@");
    SKIP: { skip("No IO::Multiplex installed\n", 2) };
    exit;
}

use_ok('Net::Server::Multiplex');
@Net::Server::Test::ISA = qw(Net::Server::Multiplex);

### Make post_bind_hook notify the client that
### the server is ready to accept connections.
sub post_bind_hook { $env->{'signal_ready_to_test'}->() }

sub mux_connection {
    my $self = shift;
    shift; shift; # These two args are boring
    print "Welcome to \"".ref($self)."\" ($$)\n";
}

sub mux_input {
    my $self = shift;
    my $mux  = shift;
    my $fh   = shift;
    my $data = shift;  # Scalar reference to the input

    # Process each line in the input, leaving partial lines
    # in the input buffer
    while ($$data =~ s/^(.*?\n)//) {
        $_ = $1;
        s/\r?\n$//;

        print ref($self),":$$: You said \"$_\"\r\n";
        $self->log(5,$_); # very verbose log

        if( /get (\w+)/ ){
            print "$1: $self->{net_server}->{server}->{$1}\r\n";
        }

        if( /exit/ ){ $self->{net_server}->{mux}->endloop; }
    }
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

        my $remote = NetServerTest::client_connect(PeerAddr => $env->{'hostname'}, PeerPort => $env->{'ports'}->[0]) || die "Couldn't open child to sock: $!";
        my $line = <$remote>;
        die "Didn't get the type of line we were expecting: ($line)" if $line !~ /Net::Server/;
        print $remote "exit\n";
        return 1;

    ### child does the server
    } else {
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
            diag("Trouble running server: $@");
            kill(9, $ppid) && ok(0, "Failed during run of server");
        };
        exit;
    }
    alarm(0);
};
alarm(0);
ok($ok, "Got the correct output from the server") || diag("Error: $@");

