package t::TestWSP;

use strict;
use warnings;

use Test::Mojo;
use t::SampleRPC;
use Net::EmptyPort qw/empty_port/;

use Exporter qw(import);
our @EXPORT_OK = qw(test_wsp);

sub test_wsp(&$;@) {
    my ($code, $app_class, $responder_class) = @_;

    my $rpc_port = empty_port;
    my $rpc_url  = "http://127.0.0.1:$rpc_port/rpc/";
    local $ENV{T_TestWSP_RPC_URL} = $rpc_url;

    $responder_class //= "t::SampleRPC";

    my $rpc = Mojo::Server::Daemon->new(
        app    => $responder_class->new,
        listen => [$rpc_url],
    );
    $rpc->start;

    my $app = $app_class->new;
    # keep reference to prevent destruction;
    $app->{_rpc} = $rpc;

    my $t = Test::Mojo->new;
    $t->app($app);

    $code->($t);
}

1;
