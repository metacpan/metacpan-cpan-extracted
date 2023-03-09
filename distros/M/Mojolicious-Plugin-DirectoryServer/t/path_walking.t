use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use File::Basename;

my $dir = dirname(__FILE__);
plugin 'DirectoryServer', root => $dir;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

subtest good_paths => sub {
	$t->get_ok('/')->status_is(200);
	$t->get_ok('/dir/index.html')->status_is(200);
	$t->get_ok('/foo/bar/buz')->status_is(404);
	};

subtest '.. paths' => sub {
	$t->get_ok('/..')->status_is(404);
	$t->get_ok('/dir/../index.html')->status_is(404);
	};

done_testing();
