use strict;
use warnings;

use Test::More;
use Encode ();
use File::Temp ();
use Mojolicious;
use Mojo::Date;
use Mojo::Util qw(gunzip);
use Test::Mojo;

my $LONG = '<p>' . ('The quick brown fox jumps over the lazy dog. ' x 10) . '</p>';
my $BIG = '<html><body>' . ('<p>The quick brown fox jumps over the lazy dog.</p>' x 100) . '</body></html>';

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
	$app->routes->get('/empty' => sub {
		my $c = shift;
		$c->render(data => '');
	});
	$app->routes->get('/no-content' => sub {
		my $c = shift;
		$c->render(data => $LONG, status => 204);
	});
	$app->routes->get('/unicode' => sub {
		my $c = shift;
		$c->render(text => "caf\x{e9} \x{263a} " . $LONG);
	});
	$app->routes->get('/custom' => sub {
		my $c = shift;
		$c->res->headers->content_type('application/x-custom');
		$c->render(data => $LONG, format => undef);
	});

	return $app;
}

subtest 'options are validated' => sub {
	eval { Mojolicious->new->plugin('Buffer', wibble => 1) };
	like($@, qr/unknown option 'wibble'/, 'unknown options are rejected');

	eval { Mojolicious->new->plugin('Buffer', encodings => 'gzip') };
	like($@, qr/encodings must be an array reference/, 'encodings must be an arrayref');

	eval { Mojolicious->new->plugin('Buffer', encodings => ['lzma']) };
	like($@, qr/unknown encoding 'lzma'/, 'unknown encodings are rejected');

	eval { Mojolicious->new->plugin('Buffer', compressible_types => 'text/html') };
	like($@, qr/compressible_types must be an array reference/, 'types must be an arrayref');

	eval { Mojolicious->new->plugin('Buffer', cache_lock_timeout => 0) };
	like($@, qr/cache_lock_timeout must be a positive number/, 'the lock timeout must be positive');

	eval { Mojolicious->new->plugin('Buffer', cache_lock_timeout => 'soon') };
	like($@, qr/cache_lock_timeout must be a positive number/, 'the lock timeout must be a number');

	eval { Mojolicious->new->plugin('Buffer', template_mtime_cache => {}) };
	like($@, qr/template_mtime_cache must be an object/, 'the mtime cache must be an object');

	eval { Mojolicious->new->plugin('Buffer', template_mtime_cache_duration => {}) };
	like($@, qr/template_mtime_cache_duration must be a duration/, 'the mtime cache duration must be a duration');
};

# Every option is now checked against a schema when the plugin is
# registered, rather than failing in the middle of a request
subtest 'every option has a schema and a message' => sub {
	my %bad = (
		compress_content => [[], qr/compress_content must be a true or false value/],
		rewrite_links => [{}, qr/rewrite_links must be a true or false value/],
		generate_etag => [sub {}, qr/generate_etag must be a true or false value/],
		generate_304 => [[], qr/generate_304 must be a true or false value/],
		trust_last_modified => [[], qr/trust_last_modified must be a true or false value/],
		cache_single_flight => [[], qr/cache_single_flight must be a true or false value/],
		optimise_content => [-1, qr/optimise_content must be 0, 1 or 2/],
		last_modified => [[], qr/last_modified must be 0, 1, an epoch/],
		min_compress_size => ['big', qr/min_compress_size must be a non-negative integer/],
		cache_duration => ['', qr/cache_duration must be a duration/],
		cache_key => [[], qr/cache_key must be a string or a code reference/],
		cache => [{}, qr/cache must be an object understanding get\(\), set\(\) and remove\(\)/],
		excluded_types => ['text/plain', qr/excluded_types must be an array reference/],
		vary_by => [['cookie', ''], qr/vary_by must be an array reference of header names/],
		messages => ['English', qr/messages must be a hash reference/],
		cache_lock_timeout => [-1, qr/cache_lock_timeout must be a positive number/],
		cache_lock_dir => [\'dir', qr/cache_lock_dir must be a directory path/],
	);

	for my $name (sort keys %bad) {
		my ($value, $message) = @{$bad{$name}};
		eval { Mojolicious->new->plugin('Buffer', $name => $value) };
		like($@, $message, "a bad $name is rejected with its own message");
	}

	ok(eval { Mojolicious->new->plugin('Buffer', compress_content => '', cache_lock_timeout => '0.5', last_modified => 'Sun, 06 Nov 1994 08:49:37 GMT', cache_key => sub { 'k' }); 1 },
		'false strings, fractional timeouts, date strings and coderefs are accepted')
		or diag($@);
};

subtest 'the first bad option is reported deterministically' => sub {
	# Several bad options: the sorted first one is always the one named
	for (1 .. 5) {
		eval { Mojolicious->new->plugin('Buffer', vary_by => 'x', cache => 'x', encodings => 'x') };
		like($@, qr/: cache must be an object/, 'cache sorts first and is reported');
	}
};

subtest 'messages override the catalog at registration' => sub {
	eval {
		Mojolicious->new->plugin('Buffer',
			messages => {unknown_option => q{Unbekannte Option '%{option}'}},
			wibble => 1,
		);
	};
	like($@, qr/Unbekannte Option 'wibble'/, 'an unknown option is reported in the overriding language');
};

subtest 'multibyte bodies get a byte length' => sub {
	my $t = Test::Mojo->new(build_app());
	$t->ua->transactor->compressed(0);
	$t->get_ok('/unicode')->status_is(200);

	my $expected = Encode::encode('UTF-8', "caf\x{e9} \x{263a} $LONG");
	is($t->tx->res->body, $expected, 'body is UTF-8');
	is($t->tx->res->headers->content_length, length($expected), 'Content-Length is in bytes');
};

subtest 'empty and bodiless responses' => sub {
	my $t = Test::Mojo->new(build_app());
	$t->ua->transactor->compressed(0);

	$t->get_ok('/empty')->status_is(200);
	ok(!defined($t->tx->res->headers->etag), 'no ETag for an empty body');

	$t->get_ok('/no-content')->status_is(204);
	ok(!defined($t->tx->res->headers->content_encoding), '204 is not compressed');
};

subtest 'custom compressible types' => sub {
	my $t = Test::Mojo->new(build_app(compressible_types => ['application/x-custom']));
	$t->ua->transactor->compressed(0);

	$t->get_ok('/custom' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($t->tx->res->headers->content_encoding, 'gzip', 'the custom type is compressed');
	is(gunzip($t->tx->res->body), $LONG, 'body round-trips');

	$t->get_ok('/' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	ok(!defined($t->tx->res->headers->content_encoding), 'text/html is no longer compressed');
};

subtest 'takes over compression from the renderer' => sub {
	my $app = build_app();
	is($app->renderer->compress, 0, 'the plugin turned off the renderer compression');

	my $t = Test::Mojo->new($app);
	$t->ua->transactor->compressed(0);

	$t->get_ok('/big' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($t->tx->res->headers->content_encoding, 'gzip', 'the plugin compressed it');
	is(gunzip($t->tx->res->body), $BIG, 'body was compressed once, not twice');
	ok(defined($t->tx->res->headers->etag), 'the plugin saw the unencoded body');
};

subtest 'static files are not buffered' => sub {
	my $dir = File::Temp->newdir;
	open(my $fh, '>:raw', "$dir/hello.txt") or die $!;
	print $fh $LONG;
	close $fh;

	my $app = build_app();
	$app->static->paths->[0] = $dir->dirname;

	my $t = Test::Mojo->new($app);
	$t->ua->transactor->compressed(0);

	$t->get_ok('/hello.txt' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	is($t->tx->res->body, $LONG, 'static body is unchanged');
	ok(!defined($t->tx->res->headers->content_encoding), 'static files are not compressed');

	# The static server's own conditional handling still works
	my $etag = $t->tx->res->headers->etag;
	ok(defined($etag), 'static server sets an ETag');
	$t->get_ok('/hello.txt' => {'If-None-Match' => $etag})->status_is(304);
};

subtest 'last_modified forms' => sub {
	my $coderef = Test::Mojo->new(build_app(last_modified => sub { 1600000000 }));
	$coderef->ua->transactor->compressed(0);
	$coderef->get_ok('/')->status_is(200);
	$coderef->header_is('Last-Modified' => Mojo::Date->new(1600000000)->to_string);

	my $string = Test::Mojo->new(build_app(last_modified => 'Wed, 01 Jan 2020 00:00:00 GMT'));
	$string->ua->transactor->compressed(0);
	$string->get_ok('/')->status_is(200);
	$string->header_is('Last-Modified' => 'Wed, 01 Jan 2020 00:00:00 GMT');

	SKIP: {
		skip 'cannot stat the test script', 1 unless -f $0;
		my $script = Test::Mojo->new(build_app(last_modified => 1));
		$script->ua->transactor->compressed(0);
		$script->get_ok('/')->status_is(200);
		$script->header_is('Last-Modified' => Mojo::Date->new((stat($0))[9])->to_string);
	}
};

# Params::Validate::Strict accepts undef for any type, so the plugin decides:
# undef is refused where it would quietly change behaviour (vary_by => undef
# would drop the Cookie header from the cache key) and accepted, without a
# warning, where it means "use the default"
subtest 'undef is only accepted where it means the default' => sub {
	for my $name (qw(encodings compressible_types excluded_types vary_by min_compress_size)) {
		eval { Mojolicious->new->plugin('Buffer', $name => undef) };
		like($@, qr/\Q$name\E must be/, "$name => undef is rejected");
	}

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	for my $name (qw(cache cache_key cache_duration cache_lock_timeout last_modified template_mtime_cache_duration messages)) {
		ok(eval { Mojolicious->new->plugin('Buffer', $name => undef); 1 }, "$name => undef is accepted") or diag($@);
	}
	is(scalar(@warnings), 0, 'and nothing warns') or diag(@warnings);
};

done_testing();
