use strict;
use warnings;

use CSS::Struct::Output::Raw;
use Tags::HTML::Page::Begin;
use Tags::Output::Structure;
use Test::More 'tests' => 21;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Page::Begin->new(
	'tags' => $tags,
);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'viewport'],
		['a', 'content', 'width=device-width, initial-scale=1.0'],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page with default without CSS.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Page::Begin->new(
	'http_equiv_content_type' => undef,
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'charset', 'UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page with default without http-equiv content-type.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Page::Begin->new(
	'generator' => undef,
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page without generator and without CSS.',
);

# Test.
my $css = CSS::Struct::Output::Raw->new;
$obj = Tags::HTML::Page::Begin->new(
	'css' => $css,
	'generator' => undef,
	'tags' => $tags,
	'viewport' => undef,
);
$css->put(
	['s', 'body'],
	['d', 'color', 'red'],
	['e'],
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['b', 'style'],
		['a', 'type', 'text/css'],
		['d', "body{color:red;}\n"],
		['e', 'style'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page without charset and generator and with CSS.',
);

# Test.

$obj = Tags::HTML::Page::Begin->new(
	'refresh' => 30,
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'http-equiv', 'refresh'],
		['a', 'content', 30],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with refresh.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'base_href' => 'https://skim.cz',
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'base'],
		['a', 'href', 'https://skim.cz'],
		['e', 'base'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with base href.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'base_href' => 'https://skim.cz',
	'base_target' => '_blank',
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'base'],
		['a', 'href', 'https://skim.cz'],
		['a', 'target', '_blank'],
		['e', 'base'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with base href and target.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'robots' => 'index, follow',
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'robots'],
		['a', 'content', 'index, follow'],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with robots meta.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'favicon' => 'favicon.ico',
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'link'],
		['a', 'rel', 'icon'],
		['a', 'href', 'favicon.ico'],
		['a', 'type', 'image/vnd.microsoft.icon'],
		['e', 'link'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with ICO favicon.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'favicon' => 'favicon.gif',
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'link'],
		['a', 'rel', 'icon'],
		['a', 'href', 'favicon.gif'],
		['a', 'type', 'image/gif'],
		['e', 'link'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with GIF favicon.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'favicon' => 'favicon.jpg',
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'link'],
		['a', 'rel', 'icon'],
		['a', 'href', 'favicon.jpg'],
		['a', 'type', 'image/jpeg'],
		['e', 'link'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with JPG favicon.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'favicon' => 'favicon.svg',
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'link'],
		['a', 'rel', 'icon'],
		['a', 'href', 'favicon.svg'],
		['a', 'type', 'image/svg+xml'],
		['e', 'link'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with SVG favicon.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'favicon' => 'favicon.png',
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'link'],
		['a', 'rel', 'icon'],
		['a', 'href', 'favicon.png'],
		['a', 'type', 'image/png'],
		['e', 'link'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with PNG favicon.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'css_src' => [
		{ 'link' => 'foo.css', },
		{
			'link' => 'bar.css',
			'media' => 'screen',
		},
	],
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['b', 'link'],
		['a', 'rel', 'stylesheet'],
		['a', 'href', 'foo.css'],
		['a', 'type', 'text/css'],
		['e', 'link'],

		['b', 'link'],
		['a', 'rel', 'stylesheet'],
		['a', 'href', 'bar.css'],
		['a', 'media', 'screen'],
		['a', 'type', 'text/css'],
		['e', 'link'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with PNG favicon.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'rss' => 'https://example.com/rss',
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['b', 'link'],
		['a', 'rel', 'alternate'],
		['a', 'type', 'application/rss+xml'],
		['a', 'title', 'RSS'],
		['a', 'href', 'https://example.com/rss'],
		['e', 'link'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with RSS.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'script_js' => [
		'foo();',
		'bar();',
	],
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'script'],
		['a', 'type', 'text/javascript'],
		['d', 'foo();'],
		['e', 'script'],

		['b', 'script'],
		['a', 'type', 'text/javascript'],
		['d', 'bar();'],
		['e', 'script'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with script JS.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'script_js_src' => [
		'https://example.com/js/foo.js',
		'https://example.com/js/bar.js',
	],
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'script'],
		['a', 'type', 'text/javascript'],
		['a', 'src', 'https://example.com/js/foo.js'],
		['e', 'script'],

		['b', 'script'],
		['a', 'type', 'text/javascript'],
		['a', 'src', 'https://example.com/js/bar.js'],
		['e', 'script'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with script JS links.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'html_lang' => 'cs',
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'cs'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page in default with html lang attribute.',
);

# Test.
$css = CSS::Struct::Output::Raw->new;
$obj = Tags::HTML::Page::Begin->new(
	'css' => $css,
	'generator' => undef,
	'tags' => $tags,
	'viewport' => undef,
);
$css->put;
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'title'],
		['d', 'Page title'],
		['e', 'title'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page without generator and with blank CSS.',
);

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'lang' => {},
	'tags' => $tags,
	'viewport' => undef,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['r', '<!DOCTYPE html>'],
		['r', "\n"],
		['b', 'html'],
		['a', 'lang', 'en'],
		['b', 'head'],

		['b', 'meta'],
		['a', 'http-equiv', 'Content-Type'],
		['a', 'content', 'text/html; charset=UTF-8'],
		['e', 'meta'],

		['b', 'meta'],
		['a', 'name', 'generator'],
		['a', 'content', 'Perl module: Tags::HTML::Page::Begin, Version: '.
			$Tags::HTML::Page::Begin::VERSION],
		['e', 'meta'],

		['e', 'head'],
		['b', 'body'],
	],
	'Begin of page without title (no present in lang structure).',
);
