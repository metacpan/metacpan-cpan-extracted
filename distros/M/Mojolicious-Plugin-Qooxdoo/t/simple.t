use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../example/lib';

use Test::More;
use Test::Mojo;


use_ok 'Mojolicious::Plugin::Qooxdoo';
use_ok 'Mojolicious::Plugin::Qooxdoo::JsonRpcController';
use_ok 'QxExample';

my $t = Test::Mojo->new('QxExample');

$t->get_ok('/asdfasdf')->status_is(404);

$t->get_ok('/root/unknown.txt')
  ->status_is(404);

$t->get_ok('/root/demo.txt')
  ->content_like(qr/DemoText/)
  ->status_is(200);


$t->put_ok('/root/jsonrpc','{"hello": dummy}')
  ->content_like(qr/request must be POST or GET/,'request must be post or get')
  ->status_is(500);

$t->post_ok('/root/jsonrpc','{"hello": dummy}')
  ->content_like(qr/Invalid json string/i,'bad request identified')
  ->status_is(500);

$t->post_ok('/root/jsonrpc','{"ID":1,"method":"test"}')
  ->content_like(qr/Missing 'id' property in JsonRPC request/,'bad request identified')
  ->status_is(500);

$t->post_ok('/root/jsonrpc','{"id":1,"method":"test"}')
  ->content_like(qr/Missing service property/,'missing service found');

$t->post_ok('/root/jsonrpc','{"id":1,"service":"test"}')
  ->content_like(qr/Missing method property/, 'missing method found');

$t->post_ok('/root/jsonrpc','{"id":1,"service":"test","method":"test"}')
  ->json_is('',{error=>{origin=>1,code=>2,message=>"service test not available"},id=>1},'json error for invalid service')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);

$t->post_ok('/root/jsonrpc','{"id":1,"service":"rpc","method":"test"}')
  ->json_is('',{error=>{origin=>1,code=>6,message=>"rpc access to method test denied"},id=>1},'json error for invalid method');

$t->post_ok('/root/jsonrpc','{"id":1,"service":"rpc","method":"echo"}')
  ->json_is('',{error=>{origin=>2,code=>123,message=>"Argument Required!"},id=>1},'propagating generic exception');

$t->post_ok('/root/jsonrpc','{"id":1,"service":"rpc","method":"echo","params":["hello"]}')
  ->json_is('',{id=>1,result=>'hello'},'post request');

$t->post_ok('/root/jsonrpc','{"id":1,"service":"rpc","method":"async","params":["hello"]}')
  ->json_is('',{id=>1,result=>'Delayed hello for 1.5 seconds!'},'async request');

$t->post_ok('/root/jsonrpc','{"id":1,"service":"rpc","method":"asyncException","params":[]}')
  ->json_is('',{id=>1,error=>{origin=>2,code=>334,message=>'a simple error'}},'async exception');

$t->post_ok('/root/jsonrpc','{"id":1,"service":"rpc","method":"async_p","params":["hello"]}')
  ->json_is('',{id=>1,result=>'Delayed hello for 1.5 seconds!'},'promise request');

$t->post_ok('/root/jsonrpc','{"id":1,"service":"rpc","method":"asyncException_p","params":[]}')
  ->json_is('',{id=>1,error=>{origin=>2,code=>334,message=>'a simple error'}},'promise exception');

$t->get_ok('/root/jsonrpc?_ScriptTransport_id=1&_ScriptTransport_data="id":1,"service":"rpc","method":"echo","params":["hello"]}')
  ->content_like(qr/Invalid json/, 'invalid json get request')
  ->status_is(500);

$t->get_ok('/root/jsonrpc?_ScriptTransport_id=1&_ScriptTransport_data={"id":1,"service":"rpc","method":"echo","params":["hello"]}')
  ->content_like(qr/qx.io.remote.transport.Script._requestFinished/, 'get request')
  ->content_type_is('application/javascript; charset=utf-8')
  ->status_is(200);

done_testing();

exit 0;
