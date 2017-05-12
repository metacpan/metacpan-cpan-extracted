use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;

plugin 'RenderCGI' => {default => 1, exception => 'template',};

get '/ep' => sub {
	my $c = shift;
	$c->render(handler => 'ep');
} => 'index';

get '/cgi' => sub {
	my $c = shift;
} => 'индекс';

get '/inline' => sub {
	my $c = shift;
	$c->render(inline=><<'EOT');
$c->layout('main',);
$c->title('INLINE');
h1 'Ohline!'
EOT
};

get '/empty' => sub {1};

get '/die' => sub {1};

get '/compile_err' => sub {1};

get '/include_not_exist' => sub {1};

get '/will_not_found' => sub {1};

#~ app->renderer->default_handler('cgi.pl');
#~ app->defaults(handler=>'cgi.pl');

#====== tests=============

use_ok('Test::Mojo');

my $t = Test::Mojo->new();# MyApp->new()

$t->get_ok('/ep')->status_is(200)
  ->content_like(qr'<h1>EP - OK!</h1>')
  ->content_like(qr'end part')
  ;
  
$t->get_ok('/cgi')->status_is(200)
  ->content_like(qr'CGI')
  ->content_like(qr'Transitional')
  ;

$t->get_ok('/inline')->status_is(200)
  ->content_like(qr'Ohline')
  ;

$t->get_ok('/empty')->status_is(200)
  ->content_is('')
  ;

$t->get_ok('/compile_err')->status_is(200)
  ->content_like(qr'syntax error')
  ;

$t->get_ok('/die')->status_is(200)
  ->content_like(qr'Умер')
  ;

$t->get_ok('/include_not_exist')->status_is(200)
  ->content_like(qr'does not found')
  ;

$t->get_ok('/will_not_found')->status_is(200)
  ->content_is('Template "will_not_found.html.cgi.pl" does not found')
  ;

plugin 'RenderCGI' => {default => 1, exception =>'skip',};

$t = Test::Mojo->new;

$t->get_ok('/will_not_found')->status_is(200)
  ->content_is('')
  ;


done_testing();

__DATA__

@@ index.html.ep
% layout 'main';
% title 'EP';
<h1>EP - OK!</h1>
<%= include 'part', handler=>'cgi.pl' %>
DONE!

@@ индекс.html.cgi.pl
$c->layout('main',);# handler=>'ep'
$c->title('CGI');
h1({}, esc '<CGI - фарева!>'),
$c->include('part', handler=>'cgi.pl',),# handler still cgi? NO: Template "part.html.ep" not found!

@@ part.html.cgi.pl
#
$c->include('empty',),
hr,
<<HTML,
<!-- end part -->
HTML
$c->app->log->info("The part has done")
  && undef,

@@ empty.html.cgi.pl

@@ die.html.cgi.pl
die "Умер";

@@ compile_err.html.cgi.pl
-bla-

@@ include_not_exist.html.cgi.pl
'will not found error',
$c->include('not exists',),

@@ layouts/main.html.ep
<html>
<head><title><%= title %></title></head>
<body><%= content %></body>
</html>

@@ layouts/main.html.cgi.pl
$cgi->charset('utf-8');
start_html(-title => $c->title,  -lang => 'ru-RU',),
$c->content,
$cgi->end_html,
