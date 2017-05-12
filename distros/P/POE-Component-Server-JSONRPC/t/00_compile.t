use strict;
use Test::More tests => 3;

BEGIN {
    use_ok 'POE::Component::Server::JSONRPC';
    use_ok 'POE::Component::Server::JSONRPC::Http';
    use_ok 'POE::Component::Server::JSONRPC::Tcp';
}
