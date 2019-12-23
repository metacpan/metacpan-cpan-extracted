use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

get '/:helper' => sub {
    my $c = shift;
    my $helper = $c->param('helper');

    $c->render(text => $c->$helper);
};

plugin 'Host';
plugin Host => { helper => 'raw_host' };
plugin Host => { helper => 'www_host', www => 'always' };
plugin Host => { helper => 'no_www_host', www => 'never' };

note 'Test host with no helper name or www set';
my $t = Test::Mojo->new;
$t->get_ok('/host' => { Host => 'www.mojolicious.org' })
  ->content_is('www.mojolicious.org')
  ;

$t->get_ok('/host' => { Host => 'mojolicious.org' })
  ->content_is('mojolicious.org')
  ;


note 'Test host with helper name and no www set';
$t->get_ok('/raw_host' => { Host => 'www.mojolicious.org' })
  ->content_is('www.mojolicious.org')
  ;

$t->get_ok('/raw_host' => { Host => 'mojolicious.org' })
  ->content_is('mojolicious.org')
  ;


note 'Test always www';
$t->get_ok('/www_host' => { Host => 'www.mojolicious.org' })
  ->content_is('www.mojolicious.org')
  ;

$t->get_ok('/www_host' => { Host => 'mojolicious.org' })
  ->content_is('www.mojolicious.org')
  ;

note 'Test never www';
$t->get_ok('/no_www_host' => { Host => 'www.mojolicious.org' })
  ->content_is('mojolicious.org')
  ;

$t->get_ok('/no_www_host' => { Host => 'mojolicious.org' })
  ->content_is('mojolicious.org')
  ;

done_testing;
