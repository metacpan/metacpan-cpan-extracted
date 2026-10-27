use strict;
use warnings;

use Test::More;
use Digest::MD5 qw(md5_hex);
use Mojolicious;
use Mojo::Date;
use Test::Mojo;

my $LONG = '<p>' . ('The quick brown fox jumps over the lazy dog. ' x 10) . '</p>';

sub build_app {
	my (%options) = @_;

	my $app = Mojolicious->new;
	$app->log->level('error');
	$app->plugin('Buffer', %options);
	$app->routes->get('/' => sub {
		my $c = shift;
		$c->render(text => $LONG);
	});

	return $app;
}

my $t = Test::Mojo->new(build_app());
$t->ua->transactor->compressed(0);

my $identity_etag = '"' . md5_hex($LONG) . '"';

subtest 'ETag is generated' => sub {
	$t->get_ok('/')->status_is(200);
	$t->header_is(ETag => $identity_etag);
	is($t->tx->res->headers->etag, $identity_etag, 'tag is the MD5 of the body');
};

subtest 'If-None-Match' => sub {
	$t->get_ok('/' => {'If-None-Match' => $identity_etag});
	$t->status_is(304);
	$t->header_is(ETag => $identity_etag);
	is($t->tx->res->body, '', '304 has no body');

	$t->get_ok('/' => {'If-None-Match' => 'W/' . $identity_etag})->status_is(304);
	$t->get_ok('/' => {'If-None-Match' => '*'})->status_is(304);
	$t->get_ok('/' => {'If-None-Match' => '"not the tag"'})->status_is(200);
	$t->get_ok('/' => {'If-None-Match' => "$identity_etag, \"another\""})->status_is(304);
};

subtest 'content codings have their own ETags' => sub {
	$t->get_ok('/' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	my $gzip_etag = $t->tx->res->headers->etag;
	isnt($gzip_etag, $identity_etag, 'gzip and identity representations differ');

	$t->get_ok('/' => {'Accept-Encoding' => 'gzip', 'If-None-Match' => $gzip_etag})->status_is(304);

	# The identity tag must not match the gzip representation
	$t->get_ok('/' => {'Accept-Encoding' => 'gzip', 'If-None-Match' => $identity_etag})->status_is(200);
};

subtest 'generate_etag can be turned off' => sub {
	my $no_etag = Test::Mojo->new(build_app(generate_etag => 0));
	$no_etag->ua->transactor->compressed(0);
	$no_etag->get_ok('/')->status_is(200);
	ok(!defined($no_etag->tx->res->headers->etag), 'no ETag');
	$no_etag->get_ok('/' => {'If-None-Match' => $identity_etag})->status_is(200);

	# Without an ETag, Last-Modified is the only validator left, so it answers
	# If-Modified-Since; If-None-Match still wins when it is present
	my $lm = Mojo::Date->new((stat($0))[9])->to_string;
	$no_etag->get_ok('/')->status_is(200);
	$no_etag->header_is('Last-Modified' => $lm);
	$no_etag->get_ok('/' => {'If-Modified-Since' => $lm})->status_is(304);
	$no_etag->get_ok('/' => {'If-Modified-Since' => Mojo::Date->new(time + 3600)->to_string})->status_is(304);
	$no_etag->get_ok('/' => {'If-Modified-Since' => Mojo::Date->new((stat($0))[9] - 3600)->to_string})->status_is(200);
	$no_etag->get_ok('/' => {'If-Modified-Since' => $lm, 'If-None-Match' => '"anything"'})->status_is(200);
};

subtest 'generate_304 can be turned off' => sub {
	my $no_304 = Test::Mojo->new(build_app(generate_304 => 0));
	$no_304->ua->transactor->compressed(0);
	$no_304->get_ok('/')->status_is(200);
	$no_304->header_is(ETag => $identity_etag);
	$no_304->get_ok('/' => {'If-None-Match' => $identity_etag})->status_is(200);
	is($no_304->tx->res->body, $LONG, 'body is still sent');
};

subtest 'Last-Modified' => sub {
	my $modified = 1700000000;
	my $lm = Mojo::Date->new($modified)->to_string;
	my $dated = Test::Mojo->new(build_app(last_modified => $modified));
	$dated->ua->transactor->compressed(0);

	$dated->get_ok('/')->status_is(200);
	$dated->header_is('Last-Modified' => $lm);

	# An ETag exists, so a timestamp alone cannot show the body is unchanged
	$dated->get_ok('/' => {'If-Modified-Since' => $lm})->status_is(200);
	$dated->get_ok('/' => {'If-Modified-Since' => Mojo::Date->new($modified - 3600)->to_string})->status_is(200);
	$dated->get_ok('/' => {'If-None-Match' => $identity_etag})->status_is(304);
	$dated->get_ok('/' => {'If-Modified-Since' => 'not a date'})->status_is(200);

	# If-None-Match takes precedence over If-Modified-Since
	$dated->get_ok('/' => {'If-Modified-Since' => $lm, 'If-None-Match' => '"wrong"'})->status_is(200);
	$dated->get_ok('/' => {'If-Modified-Since' => Mojo::Date->new($modified - 3600)->to_string,
		'If-None-Match' => $identity_etag})->status_is(304);
};

subtest 'Last-Modified is on by default' => sub {
	my $modified = (stat($0))[9];
	my $lm = Mojo::Date->new($modified)->to_string;

	$t->get_ok('/')->status_is(200);
	$t->header_is('Last-Modified' => $lm);

	# The template timestamp does not speak for the data a page was built from
	$t->get_ok('/' => {'If-Modified-Since' => $lm})->status_is(200);
	$t->get_ok('/' => {'If-Modified-Since' => Mojo::Date->new($modified - 3600)->to_string})->status_is(200);
	$t->get_ok('/' => {'If-None-Match' => $identity_etag})->status_is(304);
	$t->get_ok('/' => {'If-Modified-Since' => 'not a date'})->status_is(200);

	# The ETag still takes precedence over a matching If-Modified-Since
	$t->get_ok('/' => {'If-Modified-Since' => $lm, 'If-None-Match' => '"wrong"'})->status_is(200);
	$t->get_ok('/' => {'If-Modified-Since' => Mojo::Date->new($modified - 3600)->to_string,
		'If-None-Match' => $identity_etag})->status_is(304);
};

subtest 'Last-Modified can be turned off' => sub {
	my $off = Test::Mojo->new(build_app(last_modified => 0));
	$off->ua->transactor->compressed(0);
	$off->get_ok('/')->status_is(200);
	ok(!defined($off->tx->res->headers->last_modified), 'no Last-Modified header');
	$off->get_ok('/' => {'If-Modified-Since' => Mojo::Date->new(time + 3600)->to_string})->status_is(200);
};

subtest 'a data change is not answered with 304' => sub {
	my $app = Mojolicious->new;
	$app->log->level('error');
	$app->plugin('Buffer');
	$app->{value} = 'first';
	$app->routes->get('/data' => sub {
		my $c = shift;
		$c->render(text => "value: $app->{value}");
	});

	my $data = Test::Mojo->new($app);
	$data->ua->transactor->compressed(0);

	# Nothing on disk changes: only the data the page is rendered from
	$data->get_ok('/data')->status_is(200);
	my $etag = $data->tx->res->headers->etag;
	my $lm   = $data->tx->res->headers->last_modified;
	ok(defined($etag), 'the first response has an ETag');
	ok(defined($lm), 'the first response has a Last-Modified');
	is($data->tx->res->body, 'value: first', 'the first response has the old data');

	$app->{value} = 'second';

	$data->get_ok('/data' => {'If-None-Match' => $etag, 'If-Modified-Since' => $lm})
		->status_is(200);
	is($data->tx->res->body, 'value: second', 'the changed data was sent');

	my $new_etag = $data->tx->res->headers->etag;
	isnt($new_etag, $etag, 'the ETag moved with the body');

	# A client holding only the template timestamp must not be told that its
	# copy of the old data is current
	$data->get_ok('/data' => {'If-Modified-Since' => $lm})->status_is(200);
	is($data->tx->res->body, 'value: second', 'If-Modified-Since alone does not hide the change');

	# An unchanged body still revalidates
	$data->get_ok('/data' => {'If-None-Match' => $new_etag})->status_is(304);
	is($data->tx->res->body, '', 'the unchanged representation is not resent');
};

subtest 'trust_last_modified restores If-Modified-Since revalidation' => sub {
	my $modified = 1700000000;
	my $lm = Mojo::Date->new($modified)->to_string;
	my $trusting = Test::Mojo->new(build_app(
		last_modified       => $modified,
		trust_last_modified => 1,
	));
	$trusting->ua->transactor->compressed(0);

	$trusting->get_ok('/')->status_is(200);
	$trusting->header_is('Last-Modified' => $lm);
	my $etag = $trusting->tx->res->headers->etag;
	ok(defined($etag), 'a tag is still generated');

	# The opt-in lets the timestamp revalidate even though a tag exists
	$trusting->get_ok('/' => {'If-Modified-Since' => $lm})->status_is(304);
	is($trusting->tx->res->body, '', 'the trusted 304 has no body');
	$trusting->get_ok('/' => {'If-Modified-Since' => Mojo::Date->new($modified - 3600)->to_string})->status_is(200);

	# The tag still wins when the client has one
	$trusting->get_ok('/' => {'If-None-Match' => '"wrong"', 'If-Modified-Since' => $lm})->status_is(200);
	$trusting->get_ok('/' => {'If-None-Match' => $etag,
		'If-Modified-Since' => Mojo::Date->new($modified - 3600)->to_string})->status_is(304);
};

{
	package TestBuffer::Controller::Static;
	use Mojo::Base 'Mojolicious::Controller';

	has buffer_trust_last_modified => 1;

	sub page { shift->render(text => 'static page') }
}

{
	package TestBuffer::Controller::Volatile;
	use Mojo::Base 'Mojolicious::Controller';

	sub page { shift->render(text => 'volatile page') }
}

subtest 'trust_last_modified can be declared for a group of pages' => sub {
	my $modified = 1700000000;
	my $lm = Mojo::Date->new($modified)->to_string;

	my $app = Mojolicious->new;
	$app->log->level('error');
	$app->plugin('Buffer', last_modified => $modified);

	my $r = $app->routes;
	$r->get('/route' => {trust_last_modified => 1} => sub { shift->render(text => 'one route') });
	$r->get('/plain' => sub { shift->render(text => 'plain') });

	# An under route covers everything registered beneath it
	my $docs = $r->under('/docs')->to(trust_last_modified => 1);
	$docs->get('/one' => sub { shift->render(text => 'docs one') });
	$docs->get('/two' => sub { shift->render(text => 'docs two') });
	$docs->get('/live' => {trust_last_modified => 0} => sub { shift->render(text => 'live') });
	$docs->get('/override' => sub {
		my $c = shift;
		$c->stash(buffer => {trust_last_modified => 0});
		$c->render(text => 'override');
	});

	# A controller declaration covers its own actions only
	$r->namespaces(['TestBuffer::Controller']);
	$r->get('/static')->to('Static#page');
	$r->get('/volatile')->to('Volatile#page');

	my $group = Test::Mojo->new($app);
	$group->ua->transactor->compressed(0);

	$group->get_ok('/route')->status_is(200)->header_is('Last-Modified' => $lm);
	$group->get_ok('/route' => {'If-Modified-Since' => $lm})->status_is(304);

	$group->get_ok('/docs/one' => {'If-Modified-Since' => $lm})->status_is(304);
	$group->get_ok('/docs/two' => {'If-Modified-Since' => $lm})->status_is(304);

	$group->get_ok('/static' => {'If-Modified-Since' => $lm})->status_is(304);
	is($group->tx->res->body, '', 'the declared 304 has no body');

	# Everything outside a declaration still uses the tag
	$group->get_ok('/volatile' => {'If-Modified-Since' => $lm})->status_is(200);
	$group->get_ok('/plain' => {'If-Modified-Since' => $lm})->status_is(200);

	# A page inside a trusting group can opt out with a route default, or for
	# one response through the buffer stash
	$group->get_ok('/docs/live' => {'If-Modified-Since' => $lm})->status_is(200);
	$group->get_ok('/docs/override' => {'If-Modified-Since' => $lm})->status_is(200);

	# Tags still work inside the group, and the timestamp still has to match
	$group->get_ok('/docs/one')->status_is(200);
	my $etag = $group->tx->res->headers->etag;
	$group->get_ok('/docs/one' => {'If-None-Match' => $etag})->status_is(304);
	$group->get_ok('/docs/one' => {'If-None-Match' => '"wrong"', 'If-Modified-Since' => $lm})->status_is(200);
	$group->get_ok('/docs/one' => {'If-Modified-Since' => Mojo::Date->new($modified - 3600)->to_string})->status_is(200);
};

subtest 'conditional requests are only for successful GET and HEAD' => sub {
	$t->get_ok('/missing')->status_is(404);
	ok(!defined($t->tx->res->headers->etag), 'no ETag on an error page');
};

subtest 'HEAD carries the headers of the matching GET' => sub {
	$t->get_ok('/' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	my $length = $t->tx->res->headers->content_length;
	my $etag = $t->tx->res->headers->etag;

	$t->head_ok('/' => {'Accept-Encoding' => 'gzip'})->status_is(200);
	$t->header_is('Content-Length' => $length);
	$t->header_is(ETag => $etag);
	is($t->tx->res->body, '', 'HEAD has no body');
};

done_testing();
