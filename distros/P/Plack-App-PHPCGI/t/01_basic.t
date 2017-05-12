use strict;
use Test::More;
use Plack::App::PHPCGI;
use File::Which;
use Plack::Test;

my $php_cgi = which('php-cgi');

subtest 'php' => sub {
    plan skip_all => 'cannot find php-cgi' unless $php_cgi;

    my $php = Plack::App::PHPCGI->new(
        script => 't/01_test.php',
    );
    ok($php);

    test_psgi
      app => $php,
      client => sub {
          my $cb  = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/");
          my $res = $cb->($req);
          like $res->header('Content-Type'), qr!text/html!;
          like $res->content, qr/Hello World/;
          like $res->content, qr!.+/t/01_test\.php!;
      };
};

done_testing();
