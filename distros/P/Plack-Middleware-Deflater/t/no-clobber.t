use strict;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Middleware::Deflater;
$Plack::Test::Impl = "Server";

my $app = sub { [ 200, ['Content-Encoding' => 'foo'], [ 'Hello World' ] ] };

test_psgi app => Plack::Middleware::Deflater->wrap($app), client => sub {
  my $cb = shift;
  my $req = GET "http://localhost/", 'Accept-Encoding' => 'gzip', 'Accept-Encoding' => 'foo';
  my $res = $cb->($req);
  is $res->content, 'Hello World';
  is $res->header('Content-Encoding'), 'foo';
  like $res->header('Vary'), qr/Accept-Encoding/  
};

$app = sub { [ 200, ['Content-Encoding' => 'identity'], [ 'Hello World' ] ] };

test_psgi app => Plack::Middleware::Deflater->wrap($app), client => sub {
  my $cb = shift;
  my $req = GET "http://localhost/", 'Accept-Encoding' => 'gzip', 'Accept-Encoding' => 'foo';
  my $res = $cb->($req);
  is $res->decoded_content, 'Hello World';
  is $res->header('Content-Encoding'), 'gzip';
  like $res->header('Vary'), qr/Accept-Encoding/  
};

done_testing;
