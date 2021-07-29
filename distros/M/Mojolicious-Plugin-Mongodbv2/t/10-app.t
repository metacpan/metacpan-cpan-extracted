use Mojo::Base -strict;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More;

plan skip_all => 'set TEST_MONGODB to a valid mongodb connection string or default to use localhost unauthorized server' unless $ENV{TEST_MONGODB};

use Mojolicious::Lite;
use Test::Mojo;

my $pcfg = {};
$pcfg->{host} = $ENV{TEST_MONGODB} unless ($ENV{TEST_MONGODB} eq 'default');

plugin 'mongodbv2', $pcfg;

get '/connection' => sub {
    my $self = shift;
    $self->render(text => ref($self->app->mongodb_connection));
};

get '/dbname' => sub {
    my $s = shift;
    $s->render(text => $s->db->name);
};


get '/coll/:cname' => sub {
    my $s = shift;
    my $cname = $s->stash('cname');
    $s->render(text => $s->db->coll($cname)->name);
};

my $t = Test::Mojo->new;

$t->get_ok('/connection')->status_is(200)->content_is('MongoDB::MongoClient');
$t->get_ok('/dbname')->status_is(200)->content_is('mongodbv2');
$t->get_ok('/coll/collname')->status_is(200)->content_is('collname');

# change helper
$pcfg->{helper} = 'foo';

plugin 'mongodbv2', $pcfg;

get '/dbname2' => sub {
    my $s = shift;
    $s->render(text => $s->foo->name);
};

$t->get_ok('/dbname2')->status_is(200)->content_is('mongodbv2');

done_testing();
