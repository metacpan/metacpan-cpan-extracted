use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

plugin 'AutoIndex' => { index => [qw/index.htm index.html idx/] };

use Test::More tests => 6;
use Test::Mojo;

my $t = Test::Mojo->new();

$t->get_ok('/index.htm')->status_is(200)->content_is("Hell,world1!\n");

$t->get_ok('/')->status_is(200)->content_is("Hell,world1!\n");