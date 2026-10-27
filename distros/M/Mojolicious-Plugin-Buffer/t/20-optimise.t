use strict;
use warnings;

use Test::More;
use Encode ();
use Mojolicious;
use Test::Mojo;

my $HAVE_PACKER = eval { require HTML::Packer; 1 } ? 1 : 0;

my $HTML = <<'HTML';
<html>
  <head>
    <title>  A  test  page  </title>
    <!-- remove this comment -->
    <style>
      .header { color: red; }
    </style>
  </head>
  <body>
    <div>   <p>Hello   World</p>   </div>
    <a href="__ORIGIN__/page">A page</a>
    <a href="__ORIGIN__/search?q=perl">A search</a>
    <a href="__PATH__?q=perl">This page again</a>
    <img src="__ORIGIN__/logo.png">
    <script>
      var answer = 42;
    </script>
  </body>
</html>
HTML

sub build_app {
	my (%options) = @_;

	my $app = Mojolicious->new;
	$app->log->level('error');
	$app->plugin('Buffer', %options);

	$app->routes->get('/opt' => sub {
		my $c = shift;
		my $url = $c->req->url->to_abs;
		my $origin = $url->scheme . '://' . ($url->host_port // $url->host);
		my $path = $url->path->to_string;
		(my $html = $HTML) =~ s/__ORIGIN__/$origin/g;
		$html =~ s/__PATH__/$path/g;
		$c->render(text => $html);
	});
	$app->routes->get('/plain' => sub {
		my $c = shift;
		$c->render(data => $HTML, format => 'txt');
	});
	$app->routes->get('/off' => sub {
		my $c = shift;
		$c->stash(buffer => {optimise_content => 0});
		$c->render(text => $HTML);
	});

	return $app;
}

my $app = build_app(optimise_content => 1);
my $log = '';
open(my $log_fh, '>', \$log) or die $!;
$app->log->handle($log_fh);

my $t = Test::Mojo->new($app);
$t->ua->transactor->compressed(0);

subtest 'HTML is optimised' => sub {
	$t->get_ok('/opt')->status_is(200);

	my $body = $t->tx->res->body;
	cmp_ok(length($body), '<', length($HTML), 'body is smaller than the original');
	if ($HAVE_PACKER) {
		unlike($body, qr/remove this comment/, 'comments are removed');
	} else {
		like($body, qr/remove this comment/, 'comments are kept without HTML::Packer');
		unlike($log, qr/HTML::Packer failed/, 'no HTML::Packer failure was logged');
	}
	unlike($body, qr/\n\s*\n/, 'blank lines are removed');
	like($body, qr{<a href="/page">}, 'absolute link to this site became root-relative');
	like($body, qr{<a href="/search\?q=perl">}, 'absolute link with a query became root-relative');
	like($body, qr{<a href="\?q=perl">}, 'link to the current page became a query-only link');
	unlike($body, qr{<a href="/opt\?}, 'the current page path was dropped');
	like($body, qr{<img src="/logo\.png">}, 'absolute image link became root-relative');
	like($body, qr/var answer = 42/, 'JavaScript is preserved');
	is($t->tx->res->headers->content_length, length($body), 'Content-Length matches the optimised body');
};

subtest 'only HTML is optimised' => sub {
	$t->get_ok('/plain')->status_is(200);
	is($t->tx->res->body, $HTML, 'text/plain is untouched');
};

subtest 'optimise_content can be turned off per response' => sub {
	$t->get_ok('/off')->status_is(200);
	is($t->tx->res->body, $HTML, 'body is untouched');
};

subtest 'optimisation is off by default' => sub {
	my $default = Test::Mojo->new(build_app());
	$default->ua->transactor->compressed(0);
	$default->get_ok('/opt')->status_is(200);
	like($default->tx->res->body, qr/remove this comment/, 'comments are kept');
};

subtest 'level 2 works without HTML::Packer' => sub {
	plan skip_all => 'HTML::Packer is installed' if $HAVE_PACKER;

	my $app = build_app(optimise_content => 2);
	my $log = '';
	open(my $log_fh, '>', \$log) or die $!;
	$app->log->handle($log_fh);

	my $t = Test::Mojo->new($app);
	$t->ua->transactor->compressed(0);
	$t->get_ok('/opt')->status_is(200);

	my $body = $t->tx->res->body;
	like($body, qr/<p>Hello World<\/p>/, 'white space is still squashed');
	like($body, qr/remove this comment/, 'comments are still left alone');
	like($body, qr/var answer = 42/, 'JavaScript is still preserved');
	unlike($log, qr/HTML::Packer failed/, 'no HTML::Packer failure is logged');
};

{
	package TestBuffer::Controller::Optimised;
	use Mojo::Base 'Mojolicious::Controller';

	has buffer_optimise_content => 1;

	sub page { shift->render(text => '<div>   <p>Hello   World</p>   </div>') }
}

{
	package TestBuffer::Controller::PlainPage;
	use Mojo::Base 'Mojolicious::Controller';

	sub page { shift->render(text => '<div>   <p>Hello   World</p>   </div>') }
}

subtest 'optimise_content can be declared for a group of pages' => sub {
	my $page     = '<div>   <p>Hello   World</p>   </div>';
	my $squashed = qr{<div><p>Hello World</p></div>};
	my $original = qr{   <p>Hello   World</p>   };

	my $group_app = Mojolicious->new;
	$group_app->log->level('error');
	$group_app->plugin('Buffer');

	my $r = $group_app->routes;
	$r->get('/route' => {optimise_content => 1} => sub { shift->render(text => $page) });
	$r->get('/plain' => sub { shift->render(text => $page) });

	my $docs = $r->under('/docs')->to(optimise_content => 1);
	$docs->get('/one' => sub { shift->render(text => $page) });
	$docs->get('/raw' => {optimise_content => 0} => sub { shift->render(text => $page) });
	$docs->get('/override' => sub {
		my $c = shift;
		$c->stash(buffer => {optimise_content => 0});
		$c->render(text => $page);
	});

	$r->namespaces(['TestBuffer::Controller']);
	$r->get('/static')->to('Optimised#page');
	$r->get('/volatile')->to('PlainPage#page');

	my $group = Test::Mojo->new($group_app);
	$group->ua->transactor->compressed(0);

	$group->get_ok('/route')->status_is(200);
	like($group->tx->res->body, $squashed, 'a route default optimises that route');

	$group->get_ok('/docs/one')->status_is(200);
	like($group->tx->res->body, $squashed, 'an under route optimises everything below it');

	$group->get_ok('/static')->status_is(200);
	like($group->tx->res->body, $squashed, 'a controller declaration optimises its namespace');

	$group->get_ok('/plain')->status_is(200);
	like($group->tx->res->body, $original, 'a page outside the group is untouched');

	$group->get_ok('/volatile')->status_is(200);
	like($group->tx->res->body, $original, 'a controller without the declaration is untouched');

	$group->get_ok('/docs/raw')->status_is(200);
	like($group->tx->res->body, $original, 'a route default of 0 opts one page out');

	$group->get_ok('/docs/override')->status_is(200);
	like($group->tx->res->body, $original, 'the buffer stash overrides the group');
};

# The HTML with the current request's origin filled in, so link rewriting is
# visible
sub origin_html {
	my $c = shift;

	my $url    = $c->req->url->to_abs;
	my $origin = $url->scheme . '://' . ($url->host_port // $url->host);
	(my $html = $HTML) =~ s/__ORIGIN__/$origin/g;
	$html =~ s/__PATH__/$c->req->url->path->to_string/g;

	return $html;
}

{
	package TestBuffer::Controller::Preview;
	use Mojo::Base 'Mojolicious::Controller';

	has buffer_optimise_content => 1;
	has buffer_rewrite_links    => 0;

	sub page { my $c = shift; $c->render(text => main::origin_html($c)) }
}

subtest 'rewrite_links can be declared for a group of pages' => sub {
	my $app = Mojolicious->new;
	$app->log->level('error');
	$app->plugin('Buffer');

	my $r = $app->routes;
	$r->get('/rewritten' => {optimise_content => 1} => sub {
		my $c = shift;
		$c->render(text => origin_html($c));
	});
	$r->get('/kept' => {optimise_content => 1, rewrite_links => 0} => sub {
		my $c = shift;
		$c->render(text => origin_html($c));
	});

	# A preview of HTML that will be used elsewhere, so its links must survive
	my $preview = $r->under('/preview')->to(optimise_content => 1, rewrite_links => 0);
	$preview->get('/page' => sub {
		my $c = shift;
		$c->render(text => origin_html($c));
	});
	$preview->get('/override' => sub {
		my $c = shift;
		$c->stash(buffer => {rewrite_links => 1});
		$c->render(text => origin_html($c));
	});

	$r->namespaces(['TestBuffer::Controller']);
	$r->get('/preview-page')->to('Preview#page');

	my $group = Test::Mojo->new($app);
	$group->ua->transactor->compressed(0);

	$group->get_ok('/rewritten')->status_is(200);
	like($group->tx->res->body, qr{href="/page"}, 'a page outside the group has its links rewritten');

	$group->get_ok('/kept')->status_is(200);
	like($group->tx->res->body, qr{href="http://127\.0\.0\.1:\d+/page"},
		'a route default keeps absolute links');
	unlike($group->tx->res->body, qr{href="/page"}, 'the link was not rewritten');
	like($group->tx->res->body, qr{<p>Hello World</p>}, 'the page is still optimised');

	$group->get_ok('/preview/page')->status_is(200);
	like($group->tx->res->body, qr{href="http://127\.0\.0\.1:\d+/page"},
		'an under route keeps absolute links beneath it');
	like($group->tx->res->body, qr{<p>Hello World</p>}, 'the under route still optimises');

	$group->get_ok('/preview-page')->status_is(200);
	like($group->tx->res->body, qr{href="http://127\.0\.0\.1:\d+/page"},
		'a controller declaration keeps absolute links');

	$group->get_ok('/preview/override')->status_is(200);
	like($group->tx->res->body, qr{href="/page"}, 'the buffer stash overrides the group');
};

# The squasher once deleted a "+" that started a line, and collapsed the
# white space inside <pre>, <textarea> and script string literals.  Each of
# these changes what the reader sees or what a script does.
subtest 'squashing does not corrupt significant content' => sub {
	my $page = join("\n",
		'<html><body>',
		'<p>Call us on',
		'+44 20 7946 0000</p>',
		"<pre>a    b\n    indented\n\ttabbed</pre>",
		"<textarea name=\"t\">x    y\n   z</textarea>",
		'<script>var s = "x    y";',
		'var total = 1',
		'+ 2;</script>',
		'<style>p::before { content: "a    b"; }</style>',
		'</body></html>',
	);

	my $squash = Mojolicious->new;
	$squash->log->level('fatal');
	$squash->plugin('Buffer', optimise_content => 1);
	$squash->routes->get('/' => sub { shift->render(text => $page) });

	my $st = Test::Mojo->new($squash);
	$st->ua->transactor->compressed(0);
	$st->get_ok('/')->status_is(200);
	my $body = $st->tx->res->body;

	like($body, qr/\+44 20 7946 0000/, 'a "+" at the start of a line survives');
	like($body, qr/<pre>a    b\n    indented\n\ttabbed<\/pre>/, '<pre> content is untouched');
	like($body, qr/<textarea name="t">x    y\n   z<\/textarea>/, '<textarea> content is untouched');
	like($body, qr/"x    y"/, 'white space inside a script string literal survives');
	like($body, qr/1\s*\+\s*2/, 'a "+" continuing a script expression survives');
	like($body, qr/content: ?"a    b"/, 'white space inside a CSS string survives');
	cmp_ok(length($body), '<', length($page), 'the rest of the page was still optimised');
};

subtest 'a body that already contains the placeholder marker is restored exactly' => sub {
	my $page = "<p>\x00MPB0\x00MPB</p>\n  <pre>  keep  </pre>\n  <p>end</p>";

	my $marker = Mojolicious->new;
	$marker->log->level('fatal');
	$marker->plugin('Buffer', optimise_content => 1);
	$marker->routes->get('/' => sub { shift->render(data => $page, format => 'html') });

	my $mt = Test::Mojo->new($marker);
	$mt->ua->transactor->compressed(0);
	$mt->get_ok('/')->status_is(200);
	my $body = $mt->tx->res->body;

	like($body, qr/\x00MPB0\x00MPB/, 'the text that looks like a marker is kept');
	like($body, qr/<pre>  keep  <\/pre>/, 'the protected element is restored');
};

# UTF-8 continuation bytes \xA0 and \x85 look like white space to a
# Unicode-aware \s.  "a grave" is C3 A0 and "A ring" is C3 85, so squashing
# once cut such characters in half next to a tag.
subtest 'optimising keeps multi-byte UTF-8 characters whole' => sub {
	my $text = "<div>voil\x{e0}</div>\n<p>\x{c5}\n<b>ngstr\x{f6}m</b> \x{1F600}</p>\n<div>\x{420}\x{a0}</div>";

	my $utf8 = Mojolicious->new;
	$utf8->log->level('fatal');
	$utf8->plugin('Buffer', optimise_content => 1);
	$utf8->routes->get('/' => sub { shift->render(text => $text) });

	my $ut = Test::Mojo->new($utf8);
	$ut->ua->transactor->compressed(0);
	$ut->get_ok('/')->status_is(200);

	my $bytes = $ut->tx->res->body;
	my $decoded = eval { Encode::decode('UTF-8', $bytes, Encode::FB_CROAK | Encode::LEAVE_SRC) };
	ok(defined($decoded), 'the body is still valid UTF-8') or diag(unpack('H*', $bytes));
	like($decoded // '', qr/voil\x{e0}<\/div>/, 'a character before a tag survives');
	like($decoded // '', qr/\x{c5}/, 'a character before a line break survives');
	like($decoded // '', qr/\x{1F600}/, 'an emoji survives');
	like($decoded // '', qr/\x{420}\x{a0}<\/div>/, 'a no-break space is kept: it is content, not markup');
};

# Windows checks templates out with CRLF line endings.  The squasher once
# matched "\r\n" on its own, so the indentation after it survived.
subtest 'indentation after CRLF line breaks is squashed' => sub {
	my $page = join("\r\n",
		'<!doctype html>',
		'<html>',
		'  <head>',
		'    <title>CRLF</title>',
		'  </head>',
		'  <body>',
		'    <div class="card">',
		'      <h1>Heading</h1>',
		'    </div>',
		'  </body>',
		'</html>',
		'',
	);

	my $crlf = Mojolicious->new;
	$crlf->log->level('fatal');
	$crlf->plugin('Buffer', optimise_content => 1);
	$crlf->routes->get('/' => sub { shift->render(data => $page, format => 'html') });

	my $ct = Test::Mojo->new($crlf);
	$ct->ua->transactor->compressed(0);
	$ct->get_ok('/')->status_is(200);

	my $body = $ct->tx->res->body;
	unlike($body, qr/\n[ \t]+</, 'no line starts with indentation');
	unlike($body, qr/\r/, 'no carriage return is left in the white space');
	like($body, qr{<h1>Heading</h1>}, 'the content is kept');
};

subtest 'optimise_content rejects unknown levels' => sub {
	eval { Mojolicious->new->plugin('Buffer', optimise_content => 3) };
	like($@, qr/optimise_content must be 0, 1 or 2/, 'level 3 is rejected');

	eval { Mojolicious->new->plugin('Buffer', optimise_content => 'max') };
	like($@, qr/optimise_content must be 0, 1 or 2/, 'a word is rejected');
};

done_testing();
