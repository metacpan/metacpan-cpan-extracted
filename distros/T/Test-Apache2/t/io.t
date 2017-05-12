use strict;
use warnings;
use Test::More tests => 3;

use Test::Apache2::RequestRec;

my $req;

$req = Test::Apache2::RequestRec->new({
    content => '01234'
});

my $s;
$req->read($s, 2);
is($s, '01');

$req = Test::Apache2::RequestRec->new;
$req->write('01234', 2, 1);
is($req->to_response->content, '12');

$req = Test::Apache2::RequestRec->new;
$req->sendfile('t/io.t');
like($req->to_response->content, qr/^use strict;/);
