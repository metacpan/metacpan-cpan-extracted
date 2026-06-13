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
  ->content_like(qr/invalid payload format announcement/i,'bad request identified')
  ->status_is(500);

$t->post_ok('/root/jsonrpc',{ 'Content-Type' => 'application/json' }, '{"hello": dummy}')
  ->content_like(qr/invalid payload format/i,'bad request identified')
  ->status_is(500);

$t->post_ok('/root/jsonrpc', json => {ID => 1,method=>"test"})
  ->content_like(qr/Missing 'id' property in JsonRPC request/,'bad request identified')
  ->status_is(500);

$t->post_ok('/root/jsonrpc', json => {"id"=>1,"method" => "test"})
  ->content_like(qr/Missing service property/,'missing service found');

$t->post_ok('/root/jsonrpc', json => {"id" =>1,"service"=>"test"})
  ->content_like(qr/Missing method property/, 'missing method found');

$t->post_ok('/root/jsonrpc', json => {"id" => 1,"service" => "test","method"=>"test"})
  ->json_is('',{error=>{origin=>1,code=>2,message=>"service test not available"},id=>1},'json error for invalid service')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);

$t->post_ok('/root/jsonrpc', json => {"id"=>1,"service"=>"rpc","method"=>"test"})
  ->json_is('',{error=>{origin=>1,code=>6,message=>"rpc access to method test denied"},id=>1},'json error for invalid method');

$t->post_ok('/root/jsonrpc', json => {"id"=>1,"service" => "rpc","method" =>"echo"})
  ->json_is('',{error=>{origin=>2,code=>123,message=>"Argument Required!"},id=>1},'propagating generic exception');

$t->post_ok('/root/jsonrpc', json => {"id" => 1,"service" => "rpc","method" => "echo","params" => ["hello"]})
  ->json_is('',{id=>1,result=>'hello'},'post request');

$t->post_ok('/root/jsonrpc', json => {"id"=>1,"service"=>"rpc","method"=>"async","params" => ["hello"]})
  ->json_is('',{id=>1,result=>'Delayed hello for 1.5 seconds!'},'async request');

$t->post_ok('/root/jsonrpc', json => {"id" => 1,"service"=>"rpc","method"=>"asyncException","params"=>[]})
  ->json_is('',{id=>1,error=>{origin=>2,code=>334,message=>'a simple error'}},'async exception');


$t->post_ok('/root/jsonrpc',json => {"id" => 1,"service" => "rpc","method" => "async_p","params" => ["hello"]})
  ->json_is('',{id=>1,result=>'Delayed hello for 1.5 seconds!'},'promise request');
$t->post_ok('/root/jsonrpc', json => {"id"=>1,"service"=>"rpc","method"=>"asyncException_p","params"=>[]})
  ->json_is('',{id=>1,error=>{origin=>2,code=>334,message=>'a simple error'}},'promise exception');

$t->get_ok('/root/jsonrpc?_ScriptTransport_id=1&_ScriptTransport_data="id":1,"service":"rpc","method":"echo","params":["hello"]}')
  ->content_like(qr/Invalid json/, 'invalid json get request')
  ->status_is(500);

$t->get_ok('/root/jsonrpc?_ScriptTransport_id=1&_ScriptTransport_data={"id":1,"service":"rpc","method":"echo","params":["hello"]}')
  ->content_like(qr/qx.io.remote.transport.Script._requestFinished/, 'get request')
  ->content_type_is('application/javascript; charset=utf-8')
  ->status_is(200);

# --- JSON-RPC 2.0 ---

# 2.0 positional-params success
$t->post_ok('/root/jsonrpc', json => {jsonrpc=>"2.0","id"=>1,"method"=>"echo","params"=>["hello"]})
  ->json_is('',{jsonrpc=>"2.0",id=>1,result=>'hello'},'2.0 success envelope')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);

# 2.0 access-denied error (origin folded into data, integer code)
$t->post_ok('/root/jsonrpc', json => {jsonrpc=>"2.0","id"=>1,"method"=>"test"})
  ->json_is('',{jsonrpc=>"2.0",id=>1,error=>{code=>6,message=>"rpc access to method test denied",data=>{origin=>1}}},'2.0 access-denied envelope')
  ->status_is(200);

# 2.0 application exception propagated (blessed code+message -> origin 2)
$t->post_ok('/root/jsonrpc', json => {jsonrpc=>"2.0","id"=>1,"method"=>"echo","params"=>[]})
  ->json_is('',{jsonrpc=>"2.0",id=>1,error=>{code=>123,message=>"Argument Required!",data=>{origin=>2}}},'2.0 exception envelope')
  ->status_is(200);

# wrong jsonrpc version is rejected
$t->post_ok('/root/jsonrpc', json => {jsonrpc=>"1.0","id"=>1,"method"=>"echo","params"=>["hi"]})
  ->content_like(qr/Invalid 'jsonrpc' version/,'2.0 version guard')
  ->status_is(500);

# 2.0 over GET (Script transport) is rejected
$t->get_ok('/root/jsonrpc?_ScriptTransport_id=1&_ScriptTransport_data={"jsonrpc":"2.0","id":1,"method":"echo","params":["hi"]}')
  ->content_like(qr/must be POST/,'2.0 POST-only guard')
  ->status_is(500);

# 2.0 named (object) params are passed to the method as a single hashref
$t->post_ok('/root/jsonrpc', json => {jsonrpc=>"2.0","id"=>1,"method"=>"echo","params"=>{name=>"bob"}})
  ->json_is('',{jsonrpc=>"2.0",id=>1,result=>{name=>"bob"}},'2.0 named params reach method as hashref')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);

# 2.0 via the direct render_later pattern: a method that calls
# renderJsonRpcResult itself (not via a promise) must still emit a 2.0
# envelope -- the protocol mode is read from the private instance field.
$t->post_ok('/root/jsonrpc', json => {jsonrpc=>"2.0","id"=>1,"method"=>"async","params"=>["hello"]})
  ->json_is('',{jsonrpc=>"2.0",id=>1,result=>'Delayed hello for 1.5 seconds!'},'2.0 direct render_later success');

# 2.0 via direct render_later, error side (renderJsonRpcError called directly)
$t->post_ok('/root/jsonrpc', json => {jsonrpc=>"2.0","id"=>1,"method"=>"asyncException","params"=>[]})
  ->json_is('',{jsonrpc=>"2.0",id=>1,error=>{code=>334,message=>'a simple error',data=>{origin=>2}}},'2.0 direct render_later error');

done_testing();

exit 0;
