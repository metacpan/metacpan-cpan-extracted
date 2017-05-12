use strict;
use Test::More;
use Plack::App::PHPCGIFile;
use File::Which;
use Plack::Test;

my $php_cgi = which('php-cgi');

subtest 'phpcgifile' => sub {
    plan skip_all => 'cannot find php-cgi' unless $php_cgi;

    my $php = Plack::App::PHPCGIFile->new(
        root => 't/',
    );
    ok($php);

    test_psgi
      app => $php,
      client => sub {
          my $cb  = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/01_test.php");
          my $res = $cb->($req);
          like $res->header('Content-Type'), qr!text/html!;
          like $res->content, qr/Hello World/;
          like $res->content, qr!.+/t/01_test\.php!;

          my $req2 = HTTP::Request->new(GET => "http://localhost/01_test.txt");
          my $res2 = $cb->($req2);
          like $res2->header('Content-Type'), qr!text/plain!;
          like $res2->content, qr/Hello static/;
      };
};

done_testing();

