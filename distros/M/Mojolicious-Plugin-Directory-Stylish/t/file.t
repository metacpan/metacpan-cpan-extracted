use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use Test::More tests => 6;
use Test::Mojo;

use File::Basename;
use File::Spec;

my $dir = dirname(__FILE__);
plugin 'Directory::Stylish', root => File::Spec->catfile( $dir, 'dummy.txt' );

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(200)->content_like(qr/^DUMMY$/);
$t->get_ok('/foo/bar/buz')->status_is(200)->content_like(qr/^DUMMY$/);
