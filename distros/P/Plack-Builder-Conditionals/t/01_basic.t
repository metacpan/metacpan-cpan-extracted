use strict;
use Test::More;

use Plack::Builder::Conditionals;

ok( addr('192.168.2.0/24')->({ REMOTE_ADDR => '192.168.2.1' }) );
ok( addr(['192.168.2.0/24','127.0.0.1'])->({ REMOTE_ADDR => '192.168.2.1' }) );
ok( addr('!',['192.168.3.0/24'])->({ REMOTE_ADDR => '192.168.2.1' }) );

ok( addr('::1')->({ REMOTE_ADDR => '::1' }) );
ok( addr(['::1','127.0.0.1'])->({ REMOTE_ADDR => '::1' }) );
ok( addr(['::1','127.0.0.1'])->({ REMOTE_ADDR => '127.0.0.1' }) );

ok( path('/')->({ PATH_INFO => '/' }) );
ok( ! path('/')->() );
ok( ! path('/foo')->({ PATH_INFO => '/' }) );
ok( path(qr!^/foo!)->({ PATH_INFO => '/foo/bar' }) );
ok( path('!', qr!^/foo!)->({ PATH_INFO => '/baz/bar' }) );

ok( method()->({ REQUEST_METHOD => 'GET' }) );
ok( method('GET')->({ REQUEST_METHOD => 'GET' }) );
ok( method('get')->({ REQUEST_METHOD => 'GET' }) );
ok( method('!','post')->({ REQUEST_METHOD => 'GET' }) );
ok( method(qr/^(get|head)$/i)->({ REQUEST_METHOD => 'GET' }) );
ok( method(qw(GET HEAD))->({ REQUEST_METHOD => 'HEAD' }) );
ok( method('!',qr/^(post|put)$/i)->({ REQUEST_METHOD => 'GET' }) );
ok( method('!',qw(POST PUT))->({ REQUEST_METHOD => 'GET' }) );

ok( header('X-Foo')->({  HTTP_X_FOO => '100' }) );
ok( ! header('X-Foo')->({  HTTP_X_BAA => '100' }) );
ok( header('X-Foo','100')->({  HTTP_X_FOO => '100' }) );
ok( header('X-Foo', '!', '100')->({  HTTP_X_BAA => '100' }) );
ok( header('X-Foo',qr/\d+/)->({  HTTP_X_FOO => '100' }) );

ok( browser(qr/MSIE/)->({ HTTP_USER_AGENT => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; Trident/4.0)' }) );
ok( browser('!',qr!^Mozilla/4!)->({ HTTP_USER_AGENT => 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)' }) );



done_testing();

