use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin Host => { www => 'always' };

get '/' => sub {
    my $c = shift;

    $c->render(text => $c->host);
};

my $t = Test::Mojo->new;
$t->get_ok('/' => { Host => 'www.mojolicious.org' })
  ->content_is('www.mojolicious.org')
  ;

$t->get_ok('/' => { Host => 'mojolicious.org' })
  ->content_is('www.mojolicious.org')
  ;

done_testing;
