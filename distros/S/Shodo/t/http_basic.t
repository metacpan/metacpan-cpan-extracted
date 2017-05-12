use strict;
use Test::More;
use HTTP::Request::Common;
use HTTP::Response;
use Shodo;

my $shodo = Shodo->new;
ok $shodo;
my $suzuri = $shodo->new_suzuri('Just for test.');
ok $suzuri;

my $req = POST '/entry', [ id => 1, message => 'Hello Shodo' ];
$suzuri->request($req);

my $res = HTTP::Response->new(200);
$res->content('{ "message" : "success" }');
$suzuri->response($res);

ok $suzuri->doc();

done_testing;
