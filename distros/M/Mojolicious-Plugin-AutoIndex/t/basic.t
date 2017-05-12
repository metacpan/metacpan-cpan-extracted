use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

plugin 'AutoIndex';

use Test::More tests => 6;
use Test::Mojo;

my $t = Test::Mojo->new();

$t->get_ok('/index.html')->status_is(200)->content_is("Hello,world2!");

$t->get_ok('/')->status_is(200)->content_is("Hello,world2!");

