use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

plan skip_all => 'Cannot mount t/testapp' unless -r 't/testapp';

{
  use Mojolicious::Lite;
  plugin Mount => { '/testapp' => 't/testapp' };
}

my $t = Test::Mojo->new;

$t->get_ok('/testapp')->status_is(200)->content_like(qr{test<br>});

$t->get_ok('/testapp?_size=iphone-5')
  ->status_is(200)
  ->element_exists('.device.landscape.iphone-5 .screen iframe')
  ->element_exists('iframe[src][style=""]')
  ->content_like(qr{<iframe src="http://[^:]+:\d+/testapp"})
  ;

done_testing;
