use lib '.';
use t::Helper;

$ENV{THE_ANSWER} = 42;

use Mojolicious::Lite;
plugin CGI => ['/working' => cgi_script('basic.pl')];
plugin CGI => {route => '/env/basic', script => cgi_script('env.cgi')};

my $t = Test::Mojo->new;

$t->get_ok('/working')->status_is(200)->header_is('Content-Type' => 'text/custom')
  ->content_is("basic stuff\n");

$t->get_ok($t->tx->req->url->clone->path('/env/basic/foo')->query(query => 123))->status_is(200)
  ->content_like(qr{^ENVIRONMENT}m,                'ENVIRONMENT')
  ->content_like(qr{^CONTENT_LENGTH=0}m,           'CONTENT_LENGTH=0')
  ->content_like(qr{^CONTENT_TYPE=}m,              'CONTENT_TYPE=')
  ->content_like(qr{^GATEWAY_INTERFACE=CGI/1\.1}m, 'GATEWAY_INTERFACE=CGI/1\.1')
  ->content_like(qr{^HTTPS=NO}m, 'HTTPS=NO')->content_like(qr{^HTTP_COOKIE=}m, 'HTTP_COOKIE=')
  ->content_like(qr{^HTTP_HOST=(localhost|127\.0\.0\.1):\d+}m, 'HTTP_HOST=localhost:\d+')
  ->content_like(qr{^HTTP_REFERER=}m,                          'HTTP_REFERER=')
  ->content_like(qr{^HTTP_USER_AGENT=Mojolicious \(Perl\)}m, 'HTTP_USER_AGENT=Mojolicious \(Perl\)')
  ->content_like(qr{^PATH_INFO=/foo}m,                       'PATH_INFO=/foo')
  ->content_like(qr{^QUERY_STRING=query=123}m,               'QUERY_STRING=query=123')
  ->content_like(qr{^REMOTE_ADDR=\d+\S+}m,                   'REMOTE_ADDR=\d+\S+')
  ->content_like(qr{^REMOTE_HOST=[\w\.]+}m,                  'REMOTE_HOST=[\w\.]+')
  ->content_like(qr{^REMOTE_PORT=\w+}m,                      'REMOTE_PORT=\w+')
  ->content_like(qr{^REMOTE_USER=}m,                         'REMOTE_USER=')
  ->content_like(qr{^REQUEST_METHOD=GET}m,                   'REQUEST_METHOD=GET')
  ->content_like(qr{^SCRIPT_FILENAME=\S+/t/cgi-bin/env\.cgi}m,
  'SCRIPT_FILENAME=\S+/t/cgi-bin/env\.cgi')
  ->content_like(qr{^SCRIPT_NAME=/env/basic\W*$}m, 'SCRIPT_NAME=env/basic')
  ->content_like(qr{^SERVER_PORT=\d+}m,            'SERVER_PORT=\d+')
  ->content_like(qr{^SERVER_PROTOCOL=HTTP}m,       'SERVER_PROTOCOL=HTTP')
  ->content_like(qr{^SERVER_SOFTWARE=Mojolicious::Plugin::CGI}m,
  'SERVER_SOFTWARE=Mojolicious::Plugin::CGI')->content_like(qr{^THE_ANSWER=42}m, 'THE_ANSWER=42');

$t->get_ok('/env/basic/foo' => {'Referer' => 'http://thorsen.pm', 'X-Forwarded-For' => '1.2.3.4'})
  ->status_is(200)
  ->content_like(qr{^HTTP_REFERER=http://thorsen\.pm}m, 'HTTP_REFERER=http://thorsen.pm')
  ->content_like(qr{^HTTP_X_FORWARDED_FOR=1\.2\.3\.4}m, 'HTTP_X_FORWARDED_FOR=1.2.3.4');

done_testing;
