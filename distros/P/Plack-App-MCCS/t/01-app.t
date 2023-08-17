#!perl

use strict;
use Test2::V0;
use Plack::Test;
use Plack::App::MCCS;
use HTTP::Request;
use HTTP::Date;
use autodie;

my $app = Plack::App::MCCS->new(
	root => 't/rootdir/example1.com',
    ignore_file => 'mccsignore',
	types => {
		'.less' => {
			content_type => 'text/stylesheet-less',
		},
		'.css' => {
			valid_for => 360,
			cache_control => ['must-revalidate'],
		},
		'.txt' => {
			valid_for => 86400*4,
		},
	},
);

test_psgi
	app => $app->to_app,
	client => sub {
		my $cb = shift;

		# let's request mccs.png and see we're getting it
		my $req = HTTP::Request->new(GET => '/mccs.png');
		my $res = $cb->($req);
		is($res->code, 200, 'Found mccs.png');
		is($res->header('Content-Type'), 'image/png', 'Received proper content type for mccs.png');
		ok(!$res->header('Content-Encoding'), 'mccs.png is not gzipped');
		is($res->header('Content-Length'), 44152, 'Received proper content length for mccs.png');
		ok($res->header('Last-Modified'), 'Received a last-modified header for mccs.png');
		is($res->header('Cache-Control'), 'max-age=86400, public', 'Received default cache control for mccs.png');

		# let's request style.css and see we're getting a minified, gzipped version
		$req = HTTP::Request->new(GET => '/style.css', ['Accept-Encoding' => 'gzip']);
		$res = $cb->($req);
		is($res->code, 200, 'Found style.css');
		is($res->header('Content-Type'), 'text/css; charset=UTF-8', 'Received proper content type for style.css');
		is($res->header('Content-Encoding'), 'gzip', 'Received gzipped representation of style.css');
		is($res->header('Content-Length'), 152, 'Received proper content length for style.css');
		# let's also see if an ETag was created
		ok($res->header('ETag'), 'Received an ETag for style.css');
		# let's look at the cache control
		is($res->header('Cache-Control'), 'max-age=360, must-revalidate', 'Received specific cache control for style.css');

		# let's request style.css and see we're getting a minified, deflated version
		$req = HTTP::Request->new(GET => '/style.css', ['Accept-Encoding' => 'deflate']);
		my $deflated = $cb->($req);
		is($deflated->code, 200, 'Found style.css');
		is($deflated->header('Content-Encoding'), 'deflate', 'Received deflated representation of style.css');

		# let's request style.css again with an If-Not-Modified header
		$req = HTTP::Request->new(GET => '/style.css', ['If-Modified-Since' => $res->header('Last-Modified'), 'Accept-Encoding' => 'gzip']);
		my $newres = $cb->($req);
		is($newres->code, 304, 'Requested style.css again with If-Modified-Since and it has not modified');
		# let's request style.css again with an If-None-Match header
		$req = HTTP::Request->new(GET => '/style.css', ['If-None-Match' => $res->header('ETag'), 'Accept-Encoding' => 'gzip']);
		$newres = $cb->($req);
		is($newres->code, 304, 'Requested style.css again with If-None-Match and it has not modified');

		# let's request style.css again, but not accept gzipped responses
		$req = HTTP::Request->new(GET => '/style.css');
		$newres = $cb->($req);
		is($newres->code, 200, 'Requested style.css without gzip support and got a fresh representation');
		ok(!$newres->header('Content-Encoding'), 'Requested style.css without gzip support and got an unencoded representation');
		is($newres->header('Content-Length'), 159, 'Requested style.css without gzip support and got the minified version');

		# let's request script.js and see we're receiving an automatically minified version
		SKIP: {
			unless ($app->_minifiers->{js}) {
				diag("Skipping JS minification as JavaScript::Minifier::XS is unavailable");
				skip 'No JavaScript::Minifier::XS', 6;
			}

			$req = HTTP::Request->new(GET => '/script.js');
			$res = $cb->($req);
			is($res->code, 200, 'Found script.js');
			is($res->header('Content-Type'), 'application/javascript; charset=UTF-8', 'Received proper content type for script.js');
			is($res->content, q!$(document).ready(function(){var name=$('#name').val();var password=$('#password').val();showSomething(name,password);});function showSomething(name,password){alert("Hi "+name+", your password is "+password+" and I am going to broadcast it to the entire world.");}!, 'Received minified version of script.js');

			# let's request script.js again with Accept-Encoding and
			# see we're not getting the precompressed version (since
			# we're minifying and compressing that one instead)
			$req = HTTP::Request->new(GET => '/script.js', ['Accept-Encoding' => 'gzip']);
			$res = $cb->($req);
			is($res->code, 200, 'Found script.js with Accept-Encoding');
			is($res->header('Content-Encoding'), 'gzip', 'Received compressed version of script.js');
			ok($res->header('Content-Length') != 201, 'Received automatically compressed version of script.js and not precompressed');
		}

		# let's request style.less and see we're getting a proper content type (even though it's fake)
		$req = HTTP::Request->new(GET => '/style2.less');
		$res = $cb->($req);
		is($res->code, 200, 'Found style2.less');
		is($res->header('Content-type'), 'text/stylesheet-less; charset=UTF-8', 'Received proper content type for style2.less');
		my $length = $res->header('Content-Length');
		is($res->content, <<LESS
body {
	width: 100%;
	height: 100%;

	> header {
		height: 130px;
		background-color: #000;
	}

	> article {
		color: lighten('#fff', 100%); // a dumb way to get #000
	}

	> footer {
		a {
			color: #999;
			text-decoration: none;

			&:hover {
				text-decoration: underline;
			}
		}
	}
}
LESS
		, 'Received proper content for style2.less');

		# let's request style2.less with Accept-Encoding and see
		# if a gzipped representation is automatically created by IO::Compress::Gzip
        $req = HTTP::Request->new(GET => '/style2.less', ['Accept-Encoding' => 'gzip']);
        $res = $cb->($req);
        is($res->code, 200, 'Requested style2.less with Accept-Encoding and got 200 OK');
        is($res->header('Content-Encoding'), 'gzip', 'Requested style2.less with Accept-Encoding and got Content-Encoding == gzip');
        ok($res->header('Content-Length') < $length, 'Length of style2.less gzipped is lower than ungzipped');

		# let's request style3.css and see it is automatically minified
		SKIP: {
			unless ($app->_minifiers->{css}) {
				diag("Skipping CSS minification as CSS::Minifier::XS is unavailable");
				skip 'No CSS::Minifier::XS', 2;
			}

			$req = HTTP::Request->new(GET => '/style3.css');
			$res = $cb->($req);
			is($res->code, 200, 'Requested style3.css and received 200 OK');
			is($res->content, 'body{padding:2em}h1{font-size:36px;font-weight:bold}p{font-family:Arial,Helvetica;font-size:16px;line-height:28px}ul{margin:0;padding:0}', 'Requested style3.css and got an automatically minified version');
		}

		# let's request a file that does not exist
		$req = HTTP::Request->new(GET => '/i_dont_exist.txt');
		$res = $cb->($req);
		is($res->code, 404, 'Non-existant file returns 404');

		# let's try to trick the server into letting us view other directories
		$req = HTTP::Request->new(GET => '/../../some_important_file_with_password');
		$res = $cb->($req);
		is($res->code, 403, 'Forbidden to climb up the tree');

		# let's see the app falls back to text/plain when file has
		# no extension
		$req = HTTP::Request->new(GET => '/text');
		$res = $cb->($req);
		is($res->code, 200, 'Found text file');
		is($res->header('Content-Type'), 'text/plain; charset=UTF-8', 'text file has proper text/plain content type');

		# let's try to get a directory and see we're getting 403 Forbidden
		$req = HTTP::Request->new(GET => '/dir');
		$res = $cb->($req);
		is($res->code, 403, 'Not allowed to get directories');

		# let's get a file in a subdirectory
		$req = HTTP::Request->new(GET => '/dir/subdir/smashingpumpkins.txt');
		$res = $cb->($req);
		is($res->code, 200, 'Found file in a subdirectory');
		is($res->content, "The Smashing Pumpkins\n", 'file in a subdirectory has correct content');

        # let's make sure requests that match the .mccsignore file return 404
        $req = HTTP::Request->new(GET => '/.hidden/file');
        $res = $cb->($req);
        is($res->code, 404, '.hidden/file is ignored in .mccsignore');

        $req = HTTP::Request->new(GET => '/ignore-this.pl');
        $res = $cb->($req);
        is($res->code, 404, 'ignore-this.pl is ignored in .mccsignore');

        # the ignore file itself should not be accessible
        $req = HTTP::Request->new(GET => '/mccsignore');
        $res = $cb->($req);
        is($res->code, 404, 'ignore file itself is inaccessible');
	};

# let's quickly test one request that shouldn't allow caching
test_psgi
	app => Plack::App::MCCS->new(
		root => 't/rootdir/example1.com',
        ignore_file => 'mccsignore',
		default_cache_control => ['no-cache', 'no-store'],
		default_valid_for => -900,
	)->to_app,
	client => sub {
		my $cb = shift;

		# let's request mccs.png and see we're getting it
		my $req = HTTP::Request->new(GET => '/mccs.png');
		my $res = $cb->($req);
		is($res->header('Expires'), time2str(0), 'Expires header for mccs.png way in the past');
		is($res->header('Cache-Control'), 'no-cache, no-store', 'Received a user default cache control for mccs.png');
		ok(!$res->header('ETag'), 'Received a representation with no ETag since no-store is enforced (for mccs.png)');
	};

# remove files created by this test suit
unlink grep { -e }
      't/rootdir/example1.com/mccs.png.etag',
      't/rootdir/example1.com/script.min.js',
      't/rootdir/example1.com/script.min.js.etag',
      't/rootdir/example1.com/script.min.js.gz',
      't/rootdir/example1.com/script.min.js.gz.etag',
      't/rootdir/example1.com/style.min.css.etag',
      't/rootdir/example1.com/style.min.css.gz.etag',
      't/rootdir/example1.com/style2.less.gz',
      't/rootdir/example1.com/style2.less.etag',
      't/rootdir/example1.com/style2.less.gz.etag',
      't/rootdir/example1.com/style3.min.css',
      't/rootdir/example1.com/style3.min.css.etag',
      't/rootdir/example1.com/text.etag',
      't/rootdir/example1.com/dir/subdir/smashingpumpkins.txt.etag';

$app->min_cache_dir("min_cache");
test_psgi
	app => $app->to_app,
	client => sub {
		my $cb = shift;

		# let's request script.js and see we're receiving an automatically minified version
		SKIP: {
			unless ($app->_minifiers->{js}) {
				diag("Skipping JS minification as JavaScript::Minifier::XS is unavailable");
				skip 'No JavaScript::Minifier::XS', 7;
			}

			my $req = HTTP::Request->new(GET => '/dir/subdir/script.js');
			my $res = $cb->($req);
			is($res->code, 200, 'Found script.js');
			is($res->header('Content-Type'), 'application/javascript; charset=UTF-8', 'Received proper content type for script.js');
			is($res->content, q!$(document).ready(function(){var name=$('#name').val();var password=$('#password').val();showSomething(name,password);});function showSomething(name,password){alert("Hi "+name+", your password is "+password+" and I am going to broadcast it to the entire world.");}!, 'Received minified version of script.js');
			ok(-f "t/rootdir/example1.com/min_cache/%2Fdir%2Fsubdir%2Fscript.min.js", "minified file created in cache dir");
			ok(-f "t/rootdir/example1.com/min_cache/%2Fdir%2Fsubdir%2Fscript.min.js.etag", "etag file created in cache dir");
			ok(!-f "t/rootdir/example1.com/dir/subdir/script.min.js", "no minified file created in data dir");
			ok(!-f "t/rootdir/example1.com/dir/subdir/script.min.js.etag", "no etag file created in data dir");

                  unlink grep { -e }
                        "t/rootdir/example1.com/min_cache/%2Fdir%2Fsubdir%2Fscript.min.js",
                        "t/rootdir/example1.com/min_cache/%2Fdir%2Fsubdir%2Fscript.min.js.etag",
                        "t/rootdir/example1.com/dir/subdir/smashingpumpkins.txt.etag";
                  rmdir "t/rootdir/example1.com/min_cache";
		}

		# let's get a file in a subdirectory
		my $req = HTTP::Request->new(GET => '/dir/subdir/smashingpumpkins.txt');
		my $res = $cb->($req);
		is($res->code, 200, 'Found file in a subdirectory');
		is($res->content, "The Smashing Pumpkins\n", 'file in a subdirectory has correct content');
		ok(-f "t/rootdir/example1.com/dir/subdir/smashingpumpkins.txt.etag", "etag file for unminified file remains in data dir");
	};

# test virtal-hosts mode
$app = Plack::App::MCCS->new(
	root => 't/rootdir',
    ignore_file => 'mccsignore',
    vhost_mode => 1,
    minify => 0,
    compress => 0,
    etag => 0,
);
test_psgi
	app => $app->to_app,
	client => sub {
		my $cb = shift;

		my $req = HTTP::Request->new(GET => '/text');
        $req->remove_header('Host');
		my $res = $cb->($req);
        is($res->code, 404);

        $req->header('Host', 'example1.com');
        $res = $cb->($req);
        is($res->code, 200);

        $req->header('Host', 'example2.com');
        $res = $cb->($req);
        is($res->code, 404);

        $req = HTTP::Request->new(GET => '/index.html');
        $req->header('Host', 'example2.com');
        $res = $cb->($req);
        is($res->code, 200);
        is($res->content, "This is a test\n");

        $req = HTTP::Request->new(GET => '/ignore-this.pl');
        $req->header('Host', 'example1.com');
        $res = $cb->($req);
        is($res->code, 404, 'ignore-this.pl is ignored in example1.com');

        $req = HTTP::Request->new(GET => '/mccsignore');
        $req->header('Host', 'example1.com');
        $res = $cb->($req);
        is($res->code, 404, 'ignore file itself is inaccessible');

        $req = HTTP::Request->new(GET => '/ignore-this.pl');
        $req->header('Host', 'example2.com');
        $res = $cb->($req);
        is($res->code, 200, 'ignore-this.pl is not ignored in example2.com');
	};

done_testing();
