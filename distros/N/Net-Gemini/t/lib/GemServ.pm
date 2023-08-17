package GemServ;
use Net::Gemini::Server;
use Test2::Tools::Basic;    # bail_out, diag

sub with_server {
    my ( $param ) = @_;
    my $server = Net::Gemini::Server->new(
        listen => {
            LocalAddr => $param->{host},
            LocalPort => 0,       # get a random port
        },
        context => {
            $param->{buggy_context}
            ? ()
            : ( SSL_cert_file => $param->{cert},
                SSL_key_file  => $param->{key},
            )
        }
    );
    my $port = $server->port;
    my $pid  = fork;
    bail_out("fork failed: $!") unless defined $pid;
    unless ($pid) {
        shift @_;
        $server->withforks(@_);
        diag "server left listen loop??\n";
        exit 1;
    }
    close $server->socket;
    return $pid, $port;
}
1;
