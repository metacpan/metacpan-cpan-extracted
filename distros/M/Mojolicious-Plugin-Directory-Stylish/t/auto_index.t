use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use Test::More tests => 2;
use Test::Mojo;

use File::Basename;

my $dir = dirname(__FILE__);
plugin 'Directory::Stylish', root => $dir, auto_index => 0;

my $t = Test::Mojo->new();

$t->get_ok('/')->status_is(404);
