use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use Test::More tests => 3;
use Test::Mojo;

use File::Basename;
use Mojo::File;
use Encode ();

my $dir = dirname(__FILE__);
plugin
    'Directory::Stylish',
    root      => Mojo::File->new($dir)->child('dir'),
    dir_index => [qw/index.html index.htm/];

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(200)->text_like('body' => qr'^\s*Hello World\s*$');
