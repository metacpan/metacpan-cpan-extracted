use Test::More;
use Test::Mojo;
use Data::Dumper;
use strict;
use warnings;

$Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;

my $t = Test::Mojo->new( 't::MojoTestServer' );
$t->get_ok('/')->status_is(200)->content_is('This is t::MojoTestServer');

# hello.php: a Hello World script with no actual PHP code.
$t->get_ok('/hello.php')->status_is(200, 'data returned for hello.php')
    ->content_is('Hello, world.', 'content match for hello.php');

$t->get_ok('/bogus.php')->status_isnt(200, 'req for bogus.php failed');

# phpinfo.php: output return value of PHP's phpinfo() function
$t->get_ok('/phpinfo.php')->status_is(200, 'req for phpinfo.php')
    ->content_like( qr/html.*head.*body/is, 'phpinfo response is HTML' );
my $phpinfo_content = $t->tx->res->body;
my ($version) = $phpinfo_content =~ /PHP Version (5\.\d+\.\d+)/;
ok($version, "phpinfo for version $version");
ok( $phpinfo_content =~ /Directive.*Local Value.*Master Value/si,
    'phpinfo contains directive list');
if ($version && $version lt '5.4.0') {
    ok( $phpinfo_content =~ /magic_quotes_gpc/,
	'phpinfo contains config data' );
}
ok( $phpinfo_content =~ /Variable.*Value/, 'phpinfo contains variable data' );
ok( $phpinfo_content =~ /_SERVER/ && $phpinfo_content =~ /_ENV/,
    'phpinfo contains variable info' );

# /foo and /foo/ should run (run, not redirect) /foo/index.php
# if /foo/index.php is accessible. Otherwise, they should 404
# or drop through to whatever route they were going to take.

# test  {use_index_php}  config

$t->app->config->{'MojoX::Plugin::PHP'}{use_index_php} = 1;

$t->get_ok('/dir-b')->status_is(200)->content_like(qr/hello world/i);
$t->get_ok('/dir-b/')->status_is(200)->content_like(qr/hello world/i);
$t->get_ok('/dir-a')->status_is(404);
$t->get_ok('/dir-a/')->status_is(404);

$t->app->config->{'MojoX::Plugin::PHP'}{use_index_php} = 0;

$t->get_ok('/dir-b')->status_is(404); # 200)->content_like(qr/hello world/i);
$t->get_ok('/dir-b/')->status_is(200)->content_like(qr/hello world/i);
$t->get_ok('/dir-a')->status_is(404);
$t->get_ok('/dir-a/')->status_is(404);

delete $t->app->config->{'MojoX::Plugin::PHP'}{use_index_php};

$t->get_ok('/dir-b')->status_is(404);
$t->get_ok('/dir-b/')->status_is(404);
$t->get_ok('/dir-a')->status_is(404);
$t->get_ok('/dir-a/')->status_is(404);

done_testing();
