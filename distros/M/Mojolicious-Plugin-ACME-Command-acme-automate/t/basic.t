use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

my $t = Test::Mojo->new;
$t->get_ok('/');

done_testing();
