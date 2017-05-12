use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use Test::More tests => 3;
use Test::Mojo;

use File::Basename;

my $dir = dirname(__FILE__);
plugin 'Directory::Stylish', root => $dir, css => 'dump';

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(200);

subtest 'css' => sub {
    $t->get_ok('/')->status_is(200)->content_like(qr/marker here/);
}

__DATA__

@@ dump.html.ep
<style type='text/css'>
marker here
</style>
