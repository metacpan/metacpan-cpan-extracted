use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'SpectreCss';

get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello Mojo!');
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');
$t->get_ok('/spectre/0.5.3/core.min.css')->status_is(200)
  ->content_like(qr/Spectre\.css v0\.5\.3/);
$t->get_ok('/spectre/0.5.3/icons.min.css')->status_is(200)
  ->content_like(qr/Spectre\.css Icons v0\.5\.3/);
$t->get_ok('/spectre/0.5.3/exp.min.css')->status_is(200)
  ->content_like(qr/Spectre\.css Experimentals v0\.5\.3/);

done_testing();
