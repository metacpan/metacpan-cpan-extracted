# Test defaulting to CGI::Simple

package test::class;

use RPC::ExtDirect::Event;
use RPC::ExtDirect Action => 'test';

sub cgi : ExtDirect(0, env_arg => 1) {
    my ($class, $env) = @_;

    return $env->isa('CGI::Simple') ? \1 : \0;
}

package main;

use strict;
use warnings;

use RPC::ExtDirect::Test::Util qw/ cmp_api cmp_json /;

use Test::More;

if ( eval "require CGI::Simple" ) {
    eval "require CGI;" and
        plan tests => 3;
}
else {
    plan skip_all => 'CGI::Simple not installed';
}

use lib 't/lib';
use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Server::Test::Util;

my $static_dir = 't/htdocs';
my ($host, $port) = maybe_start_server( static_dir => $static_dir );

ok $port, "Got host: $host and port: $port";

my $router_uri = "http://$host:$port/extdirectrouter";

my $req = q|{"type":"rpc","tid":3,"action":"test","method":"cgi","data":[]}|;

my $resp = post $router_uri, { content => $req };

is_status $resp, 200, "CGI req status";

my $have = $resp->{content};
my ($want, $desc);

# If CGI::Simple <= 1.113 is installed, the Server should not use it
# But *not* if CGI.pm > 4.0 is present
if ( $CGI::Simple::VERSION > 1.113 && $CGI::VERSION < 4.0 ) {
    $desc = "CGI req status true, CGI::Simple = $CGI::Simple::VERSION";
    $want = q|{"result":true,"type":"rpc","action":"test",|.
            q|"method":"cgi","tid":3}|;
}
else {
    $desc = "CGI req status false, CGI::Simple = $CGI::Simple::VERSION";
    $want = q|{"result":false,"type":"rpc","action":"test",|.
            q|"method":"cgi","tid":3}|;
}

cmp_json $have, $want, $desc or diag explain "Response:", $resp;

