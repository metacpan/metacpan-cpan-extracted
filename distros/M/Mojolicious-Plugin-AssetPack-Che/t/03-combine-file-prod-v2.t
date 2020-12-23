use Mojo::Base -strict;
 
BEGIN {
  $ENV{MOJO_MODE}    = 'production';
  #~ $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
 
use Test::More;
 
use FindBin;
require "$FindBin::Bin/app-v2.pl";
use Mojo::File;
#Mojo::File->new("$FindBin::Bin/assets/cache")->remove_tree();


use Test::Mojo;
 
my $t = Test::Mojo->new;

is $t->get_ok('/')->status_is(200)->content_like(qr'main.css')->tx->res->dom->find('head link')->each(sub {$t->get_ok($_->attr('href'))->status_is(200); })->size, 1, 'assets count';#;

$t->get_ok('/assets/main.css')->status_is(200)->header_is('Content-Type'=>'text/css')->content_like(qr'body');
#, {'Accept-Encoding'=>'gzip'}
$t->get_ok('/assets/папка/подпапка/шаблон.html?_')->status_is(200)->header_is('Content-Type'=>'text/html;charset=UTF-8')->header_is('Content-Length'=>'56098');#62182
#~ warn $t->get_ok('/assets/шаблон.html?00000')->status_is(200)->tx->res->headers->to_string;

#~ warn $t->app->dumper($css);

Mojo::File->new("t/assets/cache")->remove_tree();

done_testing();