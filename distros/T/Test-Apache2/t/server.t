use strict;
use warnings;
use Test::More tests => 4;
use t::FooHandler;

BEGIN {
    use_ok 'Test::Apache2::Server' or die;
}

my $server = Test::Apache2::Server->new;
ok($server, 'new');

$server->location('/foo', {
    PerlResponseHandler => 't::FooHandler',
    PerlSetVar          => [ Key => 'Value' ],
});

my $resp = $server->get('/foo');
isa_ok($resp, 'HTTP::Response');
is(
    $resp->content,
    'hello world',
    'response body'
);
