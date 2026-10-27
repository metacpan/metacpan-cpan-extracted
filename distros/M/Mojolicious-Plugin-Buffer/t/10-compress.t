use strict;
use warnings;

use Test::More;
use Mojolicious;
use Test::Mojo;
use Mojo::JSON qw(decode_json);
use Mojo::Util qw(gunzip);

my $LONG = '<p>' . ('The quick brown fox jumps over the lazy dog. ' x 10) . '</p>';
my $BIG = '<html><body>' . ('<p>The quick brown fox jumps over the lazy dog.</p>' x 100) . '</body></html>';
my $SHORT = 'tiny';

sub build_app {
	my (%options) = @_;

	my $app = Mojolicious->new;
	$app->log->level('error');
	$app->plugin('Buffer', %options);

	$app->routes->get('/' => sub {
		my $c = shift;
		$c->render(text => $LONG);
	});
	$app->routes->get('/big' => sub {
		my $c = shift;
		$c->render(text => $BIG);
	});
	$app->routes->get('/short' => sub {
		my $c = shift;
		$c->render(text => $SHORT);
	});
	$app->routes->get('/plain' => sub {
		my $c = shift;
		$c->render(data => $LONG, format => 'txt');
	});
	$app->routes->get('/json' => sub {
		my $c = shift;
		$c->render(json => {message => $LONG});
	});
	$app->routes->get('/png' => sub {
		my $c = shift;
		$c->render(data => "\x89PNG\r\n\x1a\n" . $LONG, format => 'png');
	});
	$app->routes->get('/off' => sub {
		my $c = shift;
		$c->stash(buffer => {compress_content => 0});
		$c->render(text => $LONG);
	});
	$app->routes->get('/skip' => sub {
		my $c = shift;
		$c->stash(buffer => 0);
		$c->render(text => $LONG);
	});
	$app->routes->get('/encoded' => sub {
		my $c = shift;
		my $body = Mojo::Util::gzip($LONG);
		$c->res->headers->content_encoding('gzip');
		$c->render(data => $body, format => 'txt');
	});

	return $app;
}

my $t = Test::Mojo->new(build_app());
$t->ua->transactor->compressed(0);

subtest 'gzip is negotiated' => sub {
	$t->get_ok('/' => {'Accept-Encoding' => 'gzip'})->status_is(200);

	my $res = $t->tx->res;
	is($res->headers->content_encoding, 'gzip', 'Content-Encoding is gzip');
	like($res->headers->vary // '', qr/Accept-Encoding/i, 'Vary mentions Accept-Encoding');

	my $compressed = $res->body;
	cmp_ok(length($compressed), '<', length($LONG), 'body is smaller than the original');
	is(gunzip($compressed), $LONG, 'body gunzips to the original');
	is($res->headers->content_length, length($compressed), 'Content-Length is the compressed length');
};

subtest 'no Accept-Encoding means identity' => sub {
	$t->get_ok('/')->status_is(200);

	my $res = $t->tx->res;
	ok(!defined($res->headers->content_encoding), 'no Content-Encoding');
	is($res->body, $LONG, 'body is the original');
	is($res->headers->content_length, length($LONG), 'Content-Length is the uncompressed length');
	like($res->headers->vary // '', qr/Accept-Encoding/i, 'Vary still describes the negotiation');
};

subtest 'quality values are honoured' => sub {
	$t->get_ok('/' => {'Accept-Encoding' => 'gzip;q=0'})->status_is(200);
	ok(!defined($t->tx->res->headers->content_encoding), 'gzip;q=0 is not acceptable');

	$t->get_ok('/' => {'Accept-Encoding' => 'identity;q=0, gzip;q=0.5'})->status_is(200);
	is($t->tx->res->headers->content_encoding, 'gzip', 'the only acceptable coding is used');

	$t->get_ok('/' => {'Accept-Encoding' => '*;q=1'})->status_is(200);
	ok(defined($t->tx->res->headers->content_encoding), 'a wildcard accepts a supported coding');
};

subtest 'large rendered responses are handled by the plugin' => sub {
	# The renderer would otherwise have gzipped this itself, before the hook
	$t->get_ok('/big' => {'Accept-Encoding' => 'gzip'})->status_is(200);

	my $res = $t->tx->res;
	is($res->headers->content_encoding, 'gzip', 'large response is compressed');
	is(gunzip($res->body), $BIG, 'body round-trips');
	ok(defined($res->headers->etag), 'the plugin processed the large response');
};

subtest 'small bodies are left alone' => sub {
	$t->get_ok('/short' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	ok(!defined($t->tx->res->headers->content_encoding), 'short body is not compressed');
	is($t->tx->res->body, $SHORT, 'short body is unchanged');
};

subtest 'compressible types' => sub {
	$t->get_ok('/plain' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($t->tx->res->headers->content_encoding, 'gzip', 'text/plain is compressed');

	$t->get_ok('/json' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($t->tx->res->headers->content_encoding, 'gzip', 'JSON is compressed');
	is_deeply(decode_json(gunzip($t->tx->res->body)), {message => $LONG}, 'JSON survives compression');

	$t->get_ok('/png' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	ok(!defined($t->tx->res->headers->content_encoding), 'image/png is not compressed');
};

subtest 'compress_content can be turned off' => sub {
	my $no_compress = Test::Mojo->new(build_app(compress_content => 0));
	$no_compress->ua->transactor->compressed(0);
	$no_compress->get_ok('/' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	ok(!defined($no_compress->tx->res->headers->content_encoding), 'no Content-Encoding');
	ok(!defined($no_compress->tx->res->headers->vary), 'no Vary without compression');
};

subtest 'per-request stash overrides' => sub {
	$t->get_ok('/off' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	ok(!defined($t->tx->res->headers->content_encoding), 'compression is off for this response');
	is($t->tx->res->body, $LONG, 'body is unchanged');

	$t->get_ok('/skip' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	ok(!defined($t->tx->res->headers->content_encoding), 'buffer => 0 skips compression');
	ok(!defined($t->tx->res->headers->etag), 'buffer => 0 also skips the ETag');
};

{
	package TestBuffer::Controller::Assets;
	use Mojo::Base 'Mojolicious::Controller';

	has buffer_compress_content => 0;

	sub page { shift->render(text => $LONG) }
}

{
	package TestBuffer::Controller::Pages;
	use Mojo::Base 'Mojolicious::Controller';

	sub page { shift->render(text => $LONG) }
}

subtest 'compress_content can be declared for a group of pages' => sub {
	my $app = Mojolicious->new;
	$app->log->level('error');
	$app->plugin('Buffer');

	my $r = $app->routes;
	$r->get('/route' => {compress_content => 0} => sub { shift->render(text => $LONG) });
	$r->get('/plain' => sub { shift->render(text => $LONG) });

	# A section that serves files it has already compressed
	my $assets = $r->under('/assets')->to(compress_content => 0);
	$assets->get('/file' => sub { shift->render(text => $LONG) });
	$assets->get('/override' => sub {
		my $c = shift;
		$c->stash(buffer => {compress_content => 1});
		$c->render(text => $LONG);
	});

	$r->namespaces(['TestBuffer::Controller']);
	$r->get('/asset-page')->to('Assets#page');
	$r->get('/plain-page')->to('Pages#page');

	my $group = Test::Mojo->new($app);
	$group->ua->transactor->compressed(0);

	$group->get_ok('/route' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	ok(!defined($group->tx->res->headers->content_encoding), 'a route default turns compression off');
	is($group->tx->res->body, $LONG, 'the body is sent uncompressed');

	$group->get_ok('/assets/file' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	ok(!defined($group->tx->res->headers->content_encoding),
		'an under route turns compression off beneath it');
	ok(!defined($group->tx->res->headers->vary), 'no Vary where the group never compresses');

	$group->get_ok('/asset-page' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	ok(!defined($group->tx->res->headers->content_encoding),
		'a controller declaration turns compression off for its namespace');

	$group->get_ok('/plain' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($group->tx->res->headers->content_encoding, 'gzip', 'a page outside the group is still compressed');
	is(gunzip($group->tx->res->body), $LONG, 'the compressed body round-trips');

	$group->get_ok('/plain-page' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($group->tx->res->headers->content_encoding, 'gzip',
		'a controller without the declaration is still compressed');

	$group->get_ok('/assets/override' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($group->tx->res->headers->content_encoding, 'gzip', 'the buffer stash overrides the group');

	# A declaration can also opt in where the plugin is off
	my $off_app = Mojolicious->new;
	$off_app->log->level('error');
	$off_app->plugin('Buffer', compress_content => 0);
	$off_app->routes->get('/on' => {compress_content => 1} => sub { shift->render(text => $LONG) });

	my $on = Test::Mojo->new($off_app);
	$on->ua->transactor->compressed(0);
	$on->get_ok('/on' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($on->tx->res->headers->content_encoding, 'gzip', 'a declaration opts in where the plugin is off');
};

subtest 'pre-encoded responses are left alone' => sub {
	$t->get_ok('/encoded' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($t->tx->res->headers->content_encoding, 'gzip', 'Content-Encoding is unchanged');
	is(gunzip($t->tx->res->body), $LONG, 'body was not compressed twice');
};

done_testing();
