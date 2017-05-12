use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

{
  use Mojolicious::Lite;
  plugin "Responsinator";
  get "/" => sub { shift->render(text => "test\n") };
}

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->content_is("test\n");
$t->get_ok('/?_size=800x600')
  ->status_is(200)
  ->element_exists('script')
  ->element_exists('link[rel="stylesheet"]')
  ->element_exists('#select_identifier option')
  ->element_exists('#select_orientation option[value="landscape"]')
  ->element_exists('#select_orientation option[value="portrait"]')
  ->element_exists('.device.landscape .screen iframe')
  ->element_exists_not('.device.800x600.landscape')
  ->element_exists('iframe[src][style="width:800px;height:600px;"]')
  ;

$t->get_ok('/?_size=iphone-5')
  ->status_is(200)
  ->element_exists('.device.landscape.iphone-5 .screen iframe')
  ->element_exists('iframe[src][style=""]')
  ;

$t->get_ok('/?_size=iphone-5:portrait')
  ->status_is(200)
  ->element_exists('.device.portrait.iphone-5 .screen iframe')
  ->element_exists('iframe[src][style=""]')
  ;

done_testing;
