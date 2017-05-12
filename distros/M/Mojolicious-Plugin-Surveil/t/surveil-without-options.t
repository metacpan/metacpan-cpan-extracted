use Mojo::Base -base;
use Test::Mojo;
use Test::More;

{
  use Mojolicious::Lite;
  plugin 'surveil';
  get '/' => 'index';
}

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->text_is('title', 'test surveil')
  ->element_exists('script')
  ->text_like('script', qr{socket = new WebSocket\('ws://[^:]+:\d+/mojolicious/plugin/surveil'\)})
  ->text_like('script', qr{document\.body\.addEventListener})
  ;

done_testing;
__DATA__
@@ index.html.ep
<html>
<head>
<title>test surveil</title>
</head>
<body>
<button id="foo" class="bar baz">does this work?</button>
</html>
