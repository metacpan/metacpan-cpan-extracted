use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

plan skip_all => 'TEST_ONLINE=http://localhost/wp-json' unless $ENV{TEST_ONLINE};

use Mojolicious::Lite;
plugin wordpress => {base_url => $ENV{TEST_ONLINE}};

get '/pages' => sub {
  my $c = shift->render_later;
  $c->wp->get_pages_p($c->req->url->query->to_hash)->then(sub {
    my $pages = shift;
    $c->render(json => $pages);
  });
};

get '/page/:slug' => sub {
  my $c = shift->render_later;
  $c->wp->get_page_p($c->stash('slug'))->then(sub {
    my $page = shift;
    $c->render(json => $page);
  });
};

my $t = Test::Mojo->new;

$t->get_ok('/pages?per_page=2')->status_is(200)->json_has('/0/slug')->json_has('/0/title');

my $pages = $t->tx->res->json;
my $page  = $pages->[0];
my $slug  = $page->{slug} || 'unknown';
$t->get_ok("/page/$slug")->status_is(200)->json_is($page);

my $meta = $t->app->wp->meta_from($page);
ok $meta->{wp_description},           'meta description'           or note Mojo::Util::dumper($meta);
ok $meta->{wp_title},                 'meta title'                 or note Mojo::Util::dumper($meta);
ok $meta->{wp_opengraph_description}, 'meta opengraph_description' or note Mojo::Util::dumper($meta);
ok $meta->{wp_opengraph_title},       'meta opengraph_title'       or note Mojo::Util::dumper($meta);
ok $meta->{wp_twitter_description},   'meta twitter_description'   or note Mojo::Util::dumper($meta);
ok $meta->{wp_twitter_title},         'meta twitter_title'         or note Mojo::Util::dumper($meta);

$t->get_ok('/pages?all=1')->status_is(200)->json_has('/0/slug')->json_has('/0/title');
my $all_pages = $t->tx->res->json;
ok @$all_pages > @$pages, 'got all pages';

done_testing;
