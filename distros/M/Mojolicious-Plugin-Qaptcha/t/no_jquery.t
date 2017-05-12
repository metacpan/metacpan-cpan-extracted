use Test::More;
use Test::Mojo;

use Mojolicious::Lite;
use lib 'lib';

plugin 'Qaptcha';

any '/' => sub {
  shift->render('index');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)
  ->content_unlike(qr'jQuery v1.8.2')
  ->content_unlike(qr'jQuery UI - v1.8.23')
  ->content_unlike(qr'jQuery.UI.iPad plugin');

done_testing;
__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
%= qaptcha_include
</head>
<body>
%= content;
</body>
</html>

@@ index.html.ep
%= layout 'default';
