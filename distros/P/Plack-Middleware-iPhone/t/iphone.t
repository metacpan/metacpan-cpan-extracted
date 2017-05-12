use strict;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Middleware::iPhone;

use Plack::Builder;

my $app = sub { return [ 200, [ 'Content-Type' => 'text/html' ], [ <<HTML ] ] };
<html>
<head>
</head>
<body>
</body>
</html>
HTML

my $wrapped = builder {
    enable "iPhone", 
        icon => 'icon.png',
        tidy => 1,
        startup_image => 'loading.png';
    $app;
};

test_psgi $wrapped, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    is $res->code, 200;
    is $res->content, <<HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2//EN">

<html>
<head>
  <meta content="width = device-width" name="viewport">
  <meta content="yes" name="apple-mobile-web-app-capable">
  <meta content="gray" name="apple-mobile-web-app-status-bar-style">
  <link href="icon.png" rel="apple-touch-icon">
  <link href="loading.png" rel="apple-touch-startup-image">

  <title></title>
</head>

<body>
</body>
</html>
HTML
};

done_testing;
