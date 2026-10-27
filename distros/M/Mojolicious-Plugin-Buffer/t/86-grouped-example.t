use strict;
use warnings;

use Test::More;
use File::Basename qw(dirname);
use File::Spec ();
use Mojo::Home;
use Test::Mojo;

# Runs the example in examples/grouped-sections, so the group declarations it
# documents are exercised rather than merely shown.

my $root    = dirname(dirname(File::Spec->rel2abs($0)));
my $example = File::Spec->catdir($root, 'examples', 'grouped-sections');
plan skip_all => 'the grouped-sections example is missing'
	unless -f File::Spec->catfile($example, 'lib', 'GroupedSections.pm');

unshift @INC, File::Spec->catdir($example, 'lib');
require GroupedSections;

my $app = GroupedSections->new;
$app->home(Mojo::Home->new($example));
$app->log->level('error');

my $has_packer = eval { require HTML::Packer; 1 } ? 1 : 0;

my $t = Test::Mojo->new($app);

# Offer gzip without letting the user agent decode it, so the headers the
# plugin produced are what the test sees
$t->ua->transactor->compressed(0);

for my $page (qw(/docs/intro /docs/install)) {
	subtest "the docs section optimises $page" => sub {
		# No Accept-Encoding, so the body is the identity HTML the
		# optimisation produced rather than a gzip stream
		$t->get_ok($page)
			->status_is(200)
			->content_type_like(qr{^text/html});

		my $res  = $t->tx->res;
		my $body = $res->body;

		like($body, qr/<title>(?:Introduction|Installation)<\/title>/,
			'the page rendered its template');
		unlike($body, qr/\n[ \t]+</, 'the indentation is squashed') or diag($body);
		unlike($body, qr/\n[ \t]{2,}\S/, 'the paragraph indentation is squashed')
			or diag($body);
		unlike($body, qr/This comment and the indentation are what optimise_content removes/,
			'the comment is removed when HTML::Packer is installed')
			if $has_packer;
		ok($res->headers->etag, 'the response has an ETag');

		# The section is still HTML, so it is still compressed: what the group
		# declaration changed is optimisation, not negotiation
		$t->get_ok($page => {'Accept-Encoding' => 'gzip'})->status_is(200);
		is($t->tx->res->headers->content_encoding, 'gzip',
			'the docs section is still compressed');
		like($t->tx->res->headers->header('Vary') // '', qr/Accept-Encoding/,
			'and varies by content coding');
	};
}

subtest 'the assets section opts out of compression in the controller' => sub {
	$t->get_ok('/assets/app.css' => {'Accept-Encoding' => 'gzip'})
		->status_is(200)
		->content_type_like(qr{^text/css});

	my $res = $t->tx->res;
	is($res->headers->content_encoding, undef,
		'the asset is not compressed, even though text/css is compressible');
	unlike($res->headers->header('Vary') // '', qr/Accept-Encoding/,
		'so it does not vary by content coding either');
	like($res->body, qr/^\.card\{background:#fff/, 'the identity bytes are sent');

	# The plugin still saw the response, so this is the declaration skipping
	# compression rather than the request missing the plugin
	ok($res->headers->etag, 'the asset still gets an ETag');
	like($res->headers->header('Cache-Control') // '', qr/max-age=86400/,
		'and the action kept its own Cache-Control');

	$t->get_ok('/assets/app.js' => {'Accept-Encoding' => 'gzip'})
		->status_is(200)
		->content_type_like(qr{^application/javascript});
	is($t->tx->res->headers->content_encoding, undef,
		'the JavaScript asset is not compressed either');
	like($t->tx->res->body, qr/^document\.addEventListener/,
		'the identity JavaScript is sent');
};

subtest 'the example sends visitors to the docs section' => sub {
	$t->get_ok('/')->status_is(302)->header_like(Location => qr{/docs/intro$});
};

done_testing();
