use strict;
use warnings;

use Test::More;
use Errno qw(ENOENT ENOTDIR);
use File::Path qw(remove_tree);
use File::Spec ();
use File::Temp ();
use Mojo::IOLoop;
use Mojo::Promise;
use Mojolicious;
use Mojolicious::Plugin::Buffer::Lock::File;
use POSIX qw(setlocale LC_ALL);
use Test::Mojo;

# Two kinds of locale.
#
# Geographic: the plugin knows nothing about countries, but an application
# that localises or restricts pages by country relies on the cache keeping
# one country's page away from another country's visitors.  These tests use
# a country taken from a CDN header (as Cloudflare's CF-IPCountry) or from
# the client address through IP::Country::Fast, and check the cache honours
# it, including for blocked countries and concurrent requests.
#
# System: OS error strings ($!) reach users through the lock backend.  They
# are compared with the text Perl itself gives for the same errno, read
# with "local $! = ERRNO", rather than with POSIX::strerror(), whose C
# library text can differ from Perl's own.

# Requests come from 127.0.0.1; let X-Forwarded-For stand in for a client
# address so the GeoIP lookup has something real to resolve
BEGIN { $ENV{MOJO_REVERSE_PROXY} = 1 }

# Stable allocations: Google DNS, the BBC, RENATER, Deutsche Telekom DNS and
# 114DNS.  A change here means the GeoIP database has drifted, and the
# results below would be meaningless, hence BAIL_OUT.
my %KNOWN_ADDRESS = (
	US => '8.8.8.8',
	GB => '212.58.244.20',
	FR => '193.51.24.1',
	DE => '194.25.2.129',
	CN => '114.114.114.114',
);

my %GREETING = (GB => 'Hello', US => 'Howdy', FR => 'Bonjour', DE => 'Guten Tag');
my %BLOCKED = (CN => 1);

my $geo = eval { require IP::Country::Fast; IP::Country::Fast->new };

subtest 'GeoIP sanity' => sub {
	plan skip_all => 'IP::Country::Fast is not installed' unless $geo;

	for my $country (sort keys %KNOWN_ADDRESS) {
		my $found = $geo->inet_atocc($KNOWN_ADDRESS{$country}) // 'undef';
		is($found, $country, "$KNOWN_ADDRESS{$country} maps to $country")
			or BAIL_OUT("GeoIP drift: $KNOWN_ADDRESS{$country} maps to $found, not $country");
	}
};

# The visitor's country: a CDN header if there is one, else the client
# address.  Upper-cased, so "gb" and "GB" are the same visitor.
sub country_of {
	my $c = shift;

	my $header = $c->req->headers->header('CF-IPCountry');
	return uc($header) if defined($header) && length($header);
	return $geo ? ($geo->inet_atocc($c->tx->remote_address) // '**') : '**';
}

# helper_first calls buffer_is_cached before the access check, which is
# only safe when the country is part of the cache key
sub build_app {
	my (%args) = @_;

	my $helper_first = delete($args{helper_first});
	my $delay = delete($args{delay});

	my $app = Mojolicious->new;
	$app->log->level('fatal');
	$app->plugin('Buffer', %args);
	$app->{runs} = {};

	$app->routes->get('/welcome' => sub {
		my $c = shift;
		my $country = country_of($c);

		return if $helper_first && $c->buffer_is_cached;
		return $c->render(text => "Unavailable in $country", status => 451) if $BLOCKED{$country};
		return if !$helper_first && $c->buffer_is_cached;

		$app->{runs}{$country}++;
		my $page = ($GREETING{$country} // 'Welcome') . " from $country, build $app->{runs}{$country}";
		return $c->render(text => $page) unless $delay;

		# An asynchronous action, so concurrent requests really overlap
		$c->render_later;
		Mojo::IOLoop->timer($delay => sub { $c->render(text => $page) });
	});

	return $app;
}

sub fetch {
	my ($t, $country, $header) = @_;

	$t->get_ok('/welcome' => {($header // 'CF-IPCountry') => $country});
	return $t->tx->res;
}

subtest 'each country gets and caches its own page' => sub {
	my $t = Test::Mojo->new(build_app(cache => TestCache->new, vary_by => ['CF-IPCountry']));

	for my $country (qw(GB US FR DE)) {
		my $res = fetch($t, $country);
		is($res->code, 200, "$country: 200");
		is($res->headers->header('X-Cache'), 'MISS', "$country: first request misses");
		like($res->body, qr/^\Q$GREETING{$country}\E from $country, build 1$/, "$country: its own greeting");
	}

	for my $country (qw(DE FR US GB)) {
		my $res = fetch($t, $country);
		is($res->headers->header('X-Cache'), 'HIT', "$country: second request hits");
		like($res->body, qr/^\Q$GREETING{$country}\E from $country, build 1$/, "$country: still its own page");
	}
};

subtest 'a blocked country is never served or stored' => sub {
	my $cache = TestCache->new;
	my $t = Test::Mojo->new(build_app(cache => $cache, vary_by => ['CF-IPCountry'], helper_first => 1));

	fetch($t, 'GB');
	is(fetch($t, 'GB')->headers->header('X-Cache'), 'HIT', 'the GB page is cached');

	for (1 .. 2) {
		my $res = fetch($t, 'CN');
		is($res->code, 451, 'CN is refused');
		unlike($res->body, qr/Hello/, 'CN does not receive the GB page');
	}
	ok(!grep({ ($_->{body} // '') =~ /Unavailable/ } values %{$cache->{data}}), 'the refusal was never stored');
};

# The control group: the same application with the country left out of the
# key.  It shows the leak the previous test guards against is real.
subtest 'without the country in the key, pages leak across countries' => sub {
	my $t = Test::Mojo->new(build_app(cache => TestCache->new, vary_by => [], helper_first => 1));

	fetch($t, 'GB');
	my $res = fetch($t, 'CN');
	is($res->code, 200, 'CN is served...');
	like($res->body, qr/^Hello from GB/, '...the page built for GB');
};

subtest 'country handling is case-insensitive' => sub {
	# Header names: vary_by and the request disagree on case
	my $t = Test::Mojo->new(build_app(cache => TestCache->new, vary_by => ['CF-IPCountry']));
	fetch($t, 'FR', 'CF-IPCountry');
	my $res = fetch($t, 'FR', 'cf-ipcountry');
	is($res->headers->header('X-Cache'), 'HIT', 'a lower-case header name finds the same entry');

	# Header values: vary_by uses the raw value, so a lower-case code is a
	# separate (but correct) entry...
	$res = fetch($t, 'fr');
	is($res->headers->header('X-Cache'), 'MISS', 'vary_by keeps "fr" and "FR" apart');
	like($res->body, qr/^Bonjour from FR/, 'but serves the right country');

	# ...while a cache_key that normalises the code shares one entry
	my $normal = Test::Mojo->new(build_app(
		cache => TestCache->new,
		cache_key => sub { 'welcome:' . country_of($_[0]) },
	));
	fetch($normal, 'de');
	$res = fetch($normal, 'DE');
	is($res->headers->header('X-Cache'), 'HIT', 'a normalising cache_key shares "de" and "DE"');
	like($res->body, qr/^Guten Tag from DE, build 1$/, 'built once');
};

subtest 'the client address is resolved through GeoIP' => sub {
	plan skip_all => 'IP::Country::Fast is not installed' unless $geo;

	my $t = Test::Mojo->new(build_app(
		cache => TestCache->new,
		cache_key => sub { 'welcome:' . country_of($_[0]) },
	));

	for my $country (qw(GB US FR DE)) {
		$t->get_ok('/welcome' => {'X-Forwarded-For' => $KNOWN_ADDRESS{$country}})->status_is(200);
		like($t->tx->res->body, qr/^\Q$GREETING{$country}\E from $country/, "$KNOWN_ADDRESS{$country} is served the $country page");
	}
	$t->get_ok('/welcome' => {'X-Forwarded-For' => $KNOWN_ADDRESS{CN}})->status_is(451);
};

subtest 'concurrent requests from different countries' => sub {
	my $app = build_app(cache => TestCache->new, vary_by => ['CF-IPCountry'], delay => 0.2);
	my $t = Test::Mojo->new($app);

	# Five countries at once, plus two more for FR: different keys must not
	# wait for each other, and the FR duplicates must share one build
	my @countries = qw(GB US FR DE CN FR FR);
	my @promises = map {
		my $country = $_;
		$t->ua->get_p('/welcome' => {'CF-IPCountry' => $country})->then(sub { [$country, shift->res] });
	} @countries;

	my @results;
	Mojo::Promise->all(@promises)->then(sub { @results = map { $_->[0] } @_ })->wait;
	is(scalar(@results), scalar(@countries), 'every request was answered');

	for my $result (@results) {
		my ($country, $res) = @$result;
		if ($BLOCKED{$country}) {
			is($res->code, 451, "$country: refused");
			next;
		}
		is($res->code, 200, "$country: 200, not a 503 from waiting on another country");
		like($res->body, qr/^\Q$GREETING{$country}\E from $country, build 1$/, "$country: its own page");
	}

	is($app->{runs}{FR}, 1, 'three concurrent FR requests ran the action once');
	is($app->{runs}{$_}, 1, "$_ ran once") for qw(GB US DE);
};

subtest 'concurrent application instances sharing a cache' => sub {
	# Two workers of the same application: separate plugin instances and
	# in-flight tables, one shared cache.  Each Test::Mojo listens on its own
	# port, so send the Host a real site's workers would all see.
	my $cache = TestCache->new;
	my $one = Test::Mojo->new(build_app(cache => $cache, vary_by => ['CF-IPCountry']));
	my $two = Test::Mojo->new(build_app(cache => $cache, vary_by => ['CF-IPCountry']));
	my $site = sub {
		my ($t, $country) = @_;
		$t->get_ok('/welcome' => {Host => 'www.example.com', 'CF-IPCountry' => $country});
		return $t->tx->res;
	};

	$site->($one, 'GB');
	$site->($two, 'US');

	my $res = $site->($two, 'GB');
	is($res->headers->header('X-Cache'), 'HIT', 'the second instance hits the entry the first built');
	like($res->body, qr/^Hello from GB/, 'with the GB page');

	$res = $site->($one, 'US');
	is($res->headers->header('X-Cache'), 'HIT', 'and the other way round');
	like($res->body, qr/^Howdy from US/, 'with the US page');

	# Separate caches stay separate
	my $other = Test::Mojo->new(build_app(cache => TestCache->new, vary_by => ['CF-IPCountry']));
	is($site->($other, 'GB')->headers->header('X-Cache'), 'MISS', 'an instance with its own cache does not see them');
};

# ---------------------------------------------------------------------------
# System locales
# ---------------------------------------------------------------------------

# The text Perl gives for an errno, read the way the brief requires
sub errno_text {
	my $errno = shift;

	local $! = $errno;
	return "$!";
}

my $original_locale = setlocale(LC_ALL);

for my $locale ('en_US.UTF-8', 'de_DE.UTF-8', 'ja_JP.UTF-8') {
	subtest "OS errors under LC_ALL=$locale" => sub {
		local $ENV{LC_ALL} = $locale;
		my $applied = setlocale(LC_ALL, $locale);
		note(defined($applied)
			? "the C library is now using $applied"
			: "$locale is not installed here; the C library stays in $original_locale");

		my $tmp = File::Temp->newdir('mpb-locale-XXXXXX', TMPDIR => 1);

		# ENOENT, returned: the lock directory vanishes after start-up
		my $dir = File::Spec->catdir("$tmp", 'locks');
		my $lock = Mojolicious::Plugin::Buffer::Lock::File->new(dir => $dir);
		remove_tree($dir);

		my $enoent = errno_text(ENOENT);
		my ($guard, $error) = $lock->acquire('a key');
		ok(!$guard, 'no lock without a directory');
		like($error, qr/^cannot open \Q$dir\E\S+: \Q$enoent\E$/, "the error carries Perl's ENOENT text ($enoent)");

		# Thrown: a plain file stands where a directory should be.  POSIX
		# systems say ENOTDIR; Windows says the path was not found (ENOENT)
		my $file = File::Spec->catfile("$tmp", 'plain');
		open(my $fh, '>', $file) or die "$file: $!";
		close($fh);
		my $under_file = File::Spec->catdir($file, 'locks');
		my ($errno_name, $errno) = ($^O eq 'MSWin32') ? ('ENOENT', ENOENT) : ('ENOTDIR', ENOTDIR);
		my $errno_text = errno_text($errno);

		eval { Mojolicious::Plugin::Buffer::Lock::File->new(dir => $under_file) };
		like($@, qr/cannot create cache_lock_dir '\Q$under_file\E': .*\Q$errno_text\E/,
			"new() croaks with Perl's $errno_name text ($errno_text)");

		eval { Mojolicious->new->plugin('Buffer', cache_lock_dir => $under_file) };
		like($@, qr/cannot create cache_lock_dir '\Q$under_file\E': .*\Q$errno_text\E/,
			'registering the plugin croaks with the same text');

		# The catalog text around the OS string is not localised by LC_ALL
		like($error, qr/^cannot open /, 'the surrounding message comes from the catalog');

		setlocale(LC_ALL, $original_locale);
	};
}

done_testing();

package TestCache;

sub new { bless {data => {}}, shift }
sub get { $_[0]->{data}{$_[1]} }
sub set { $_[0]->{data}{$_[1]} = $_[2]; 1 }
sub remove { delete $_[0]->{data}{$_[1]} }
