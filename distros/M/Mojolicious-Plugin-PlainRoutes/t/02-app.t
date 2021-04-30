#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use Test::Deep;
use Mojolicious;
use Mojolicious::Plugin::PlainRoutes;
use File::Temp qw/tempfile/;

my ($fh, $filename) = tempfile;
print $fh <<EOF;
ANY /game/:id -> Game.fetch {
        GET /        -> Game.view
        GET /edit    -> Game.edit
        GET /players -> Game.players
}
GET /game/create -> Game.create
GET /games/:page -> Game.list
# GET /games     -> Game.list
EOF
close $fh;

my $app = Mojolicious->new;
$app->plugin('PlainRoutes', { file => $filename });

my $r = $app->routes;
is $#{ $r->children }, 2, "Router children count";

my $bridge = $r->children->[0];
ok $bridge->inline, "First child inline";
is $#{ $bridge->children }, 2, "First child children count";
is $bridge->methods, undef, "First child methods";
is $bridge->pattern->unparsed, '/game/:id', "First child pattern";
is $bridge->pattern->defaults->{action}, 'fetch', "First child action";
is $bridge->pattern->defaults->{controller}, 'game', "First child controller";

my $route = $r->children->[1];
ok !$route->inline, "Second child inline";
is $route->methods->[0], "GET", "Second child methods";
is $route->pattern->unparsed, '/game/create', "Second child pattern";
is $route->pattern->defaults->{action}, 'create', "Second child action";
is $route->pattern->defaults->{controller}, 'game', "Second child controller";

done_testing;
