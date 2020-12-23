use Mojo::Base -strict;
 
BEGIN {
  $ENV{MOJO_MODE}    = 'production';
  #~ $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
 
use Test::More;
 
use FindBin;
require "$FindBin::Bin/app.pl";
use Mojo::File;
#Mojo::File->new("$FindBin::Bin/assets/cache")->remove_tree();


use Test::Mojo;
 
my $t = Test::Mojo->new;


is $t->get_ok('/')->status_is(200)->content_like(qr'main.css')->tx->res->dom->find('head link')->each(sub {$t->get_ok($_->attr('href'))->status_is(200)->content_like(qr'body');  })->size, 1, 'assets count';#;warn $_->attr('href'), $t->tx->res->to_string;

$t->get_ok('/assets/main.css')
  ->status_is(200)
  ->header_is('Content-Type'=>'text/css')
  #~ ->header_is('Content-Length'=>'62182')
  ->content_like(qr'body')
  ;

#~ warn $t->tx->res->to_string;

$t->get_ok('/assets/шаблон 1.html')->status_is(200)->header_is('Content-Type'=>'text/html;charset=UTF-8')->header_is('Content-Length'=>'62182');

#~ warn $t->app->dumper($css);
Mojo::File->new("t/assets/cache")->remove_tree();

done_testing();