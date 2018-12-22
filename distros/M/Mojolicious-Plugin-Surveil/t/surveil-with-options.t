use Mojo::Base -base;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;
my @e;
plugin 'surveil' => {enable_param => 'x', handler => sub { push @e, $_[1] }, path => '/some/path'};
get '/' => 'index';

my $t = Test::Mojo->new;

$t->get_ok('/')->element_exists_not('script');
$t->get_ok('/?x=1')->element_exists('script')
  ->text_like('script', qr{socket = new WebSocket\("ws://[^:]+:\d+/some/path"\)});

$t->websocket_ok('/some/path')->status_is(101)->send_ok({json => {type => 'click', target => 'a#menu'}})->finish_ok;
is_deeply \@e, [{type => 'click', target => 'a#menu'}], 'custom event handler';

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
