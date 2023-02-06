use Mojo::Base -strict;
use Test::More 0.98;

use_ok $_ for qw(
    Mojolicious::Plugin::PrometheusTiny
);

done_testing;