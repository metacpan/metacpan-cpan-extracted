use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use File::Basename;

my $dir = dirname(__FILE__);
plugin 'Directory', root => $dir, auto_index => 0;

use Test::More tests => 2;
use Test::Mojo;

my $t = Test::Mojo->new();

$t->get_ok('/')->status_is(404);
