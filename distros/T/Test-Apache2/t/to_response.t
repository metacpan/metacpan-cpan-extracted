use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok 'Test::Apache2::RequestRec' or die;
}

my $req = Test::Apache2::RequestRec->new;
$req->headers_out->add('X-One' => 'one');
$req->headers_out->add('X-Two' => 'two');

my $resp = $req->to_response;
is($resp->header('X-One'), 'one');
is($resp->header('X-Two'), 'two');
