package PMCPRpc;
use 5.010;
use strict;
use warnings;
use JSON::PP ();
use Exporter 'import';
use Punk::Plugin::MCP ();

our @EXPORT = qw(rpc rpc_raw req note jdec);

my $J = JSON::PP->new->canonical;

# A JSON-RPC request, as bytes.
sub req {
    my ($id, $method, $params) = @_;
    return $J->encode({ jsonrpc => '2.0', id => $id, method => $method,
                        (defined $params ? (params => $params) : ()) });
}

# A notification, as bytes.
sub note {
    my ($method, $params) = @_;
    return $J->encode({ jsonrpc => '2.0', method => $method,
                        (defined $params ? (params => $params) : ()) });
}

sub jdec { defined $_[0] ? JSON::PP->new->decode($_[0]) : undef }

# (status, reply bytes, negotiated, cancelled)
sub rpc_raw {
    my ($state, $bytes) = @_;
    return Punk::Plugin::MCP::_dispatch($state || {}, $bytes);
}

# (status, decoded reply), the reply decoded by JSON::PP, not by the library
# that wrote it.
sub rpc {
    my ($status, $bytes) = rpc_raw(@_);
    return ($status, jdec($bytes));
}

1;
