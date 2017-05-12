use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok 'Test::Apache2::RequestRec' or die;
}

my $req = Test::Apache2::RequestRec->new({ headers_in => { 'X-Baz' => 'hello' } });
isa_ok($req->headers_in, 'APR::Table');
is($req->headers_in->get('X-Baz'), 'hello', 'headers_in');
is($req->header_in('X-Baz'), 'hello', 'header_in');

ok($req->headers_out, 'headers_out');

$req->headers_out->set('X-FooBar' => 'One');
is($req->headers_out->get('X-FooBar'), 'One', 'headers_out set/get');

$req->header_out('X-FooBar' => 'Two');
is($req->headers_out->get('X-FooBar'), 'Two', 'header_out');
