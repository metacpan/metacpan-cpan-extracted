use v5.14;
use Mojo::Base qw{ strict };
use Test::More tests => 1;

BEGIN { use_ok 'Mojolicious::Plugin::DBICAdmin' }
