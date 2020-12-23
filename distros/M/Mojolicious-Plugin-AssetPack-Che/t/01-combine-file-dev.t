use Mojo::Base -strict;
 
BEGIN {
  $ENV{MOJO_MODE}    = 'development';
  #~ $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
 
use Test::More;
 
use FindBin;
require "$FindBin::Bin/app.pl";
use Mojo::File;

 
use Test::Mojo;
 
my $t = Test::Mojo->new;


is $t->get_ok('/')->status_is(200)->content_like(qr'foo.css')->tx->res->dom->find('head link')->each(sub {$t->get_ok($_->attr('href'))->status_is(200); })->size, 2, 'assets count';#;

$t->get_ok('/assets/main.css')->status_is(404);
$t->get_ok('/assets/шаблон 1.html')->status_is(200)->header_is('Content-Type'=>'text/html;charset=UTF-8')->header_is('Content-Length'=>'62182');

# Customize all transactions (including followed redirects)
#~ $t->ua->on(start => sub {
  #~ my ($ua, $tx) = @_;
  #~ warn $t->app->dumper(
  #~ $tx->req->headers->accept_encoding('gzip');
#~ });

#~ $t->get_ok('/assets/t1.html')->status_is(200)->header_is('Content-Type'=>'text/html;charset=UTF-8')->header_is('Content-Length'=>'62182')->header_is('Content-Encoding' => 'gzip');

#~ warn $t->app->dumper($t->tx->req->headers);
#~ warn $t->app->dumper($t->tx->res->headers);
Mojo::File->new("t/assets/cache")->remove_tree();

done_testing();

