use Mojo::Base -strict;
 
BEGIN {
  $ENV{MOJO_MODE}    = 'production';
  #~ $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
 
use Test::More;
 
use FindBin;
require "$FindBin::Bin/app-v2.pl";
 
use Test::Mojo;
 
my $t = Test::Mojo->new;


is $t->get_ok('/')->status_is(200)->content_unlike(qr'main.css')->tx->res->dom->find('head link')->each(sub {$t->get_ok($_->attr('href'))->status_is(200); })->size, 1, 'assets count';#;

$t->get_ok('/assets/main.css')->status_is(200)->header_is('Content-Type'=>'text/css')->content_like(qr'body');
$t->get_ok('/assets/t1.html')->status_is(200)->header_is('Content-Type'=>'text/html;charset=UTF-8')->header_is('Content-Length'=>'62182');

#~ warn $t->app->dumper($css);
 
done_testing();