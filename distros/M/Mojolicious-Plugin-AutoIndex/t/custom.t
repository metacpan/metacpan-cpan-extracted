use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

plugin 'AutoIndex' => { index => [qw/idx/] };

use Test::More tests => 6;
use Test::Mojo;

my $t = Test::Mojo->new();

$t->get_ok('/idx')->status_is(200)->content_is("Idx");

$t->get_ok('/')->status_is(200)->content_is("Idx");