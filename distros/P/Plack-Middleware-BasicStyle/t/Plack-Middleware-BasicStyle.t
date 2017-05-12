#!/usr/bin/perl
use 5.014000;
use warnings;

use Test::More tests => 14;
BEGIN { use_ok('Plack::Middleware::BasicStyle') };

use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

my $default_hdrs = ['Content-Type' => 'text/html; charset=utf-8'];

sub run_test {
	my ($args, $hdrs, $body, $expected, $title, $url) = @_;
	$url //= '/';
	test_psgi
	  builder {
		  enable 'BasicStyle', @$args;
		  sub { [200, $hdrs, [$body]] }
	  },
	  sub {
		  my ($cb) = @_;
		  my $result = $cb->(GET $url);
		  if (ref $expected eq 'ARRAY') {
			  my ($hdr, $exp) = @$expected;
			  is $result->header($hdr), $exp, $title
		  } else {
			  is $result->content, $expected, $title
		  }
	  }
  }

run_test [], $default_hdrs, <<'BODY', <<'EXPECTED', 'default';
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Foo</title>
</head>
<body>
<h1>Bar</h1>
</body>
</html>
BODY
<!DOCTYPE html>
<html>
<head><style>body{margin:40pxauto;max-width:650px;line-height:1.6;font-size:18px;color:#444;padding:010px}h1,h2,h3{line-height:1.2}</style>
<meta charset="utf-8">
<title>Foo</title>
</head>
<body>
<h1>Bar</h1>
</body>
</html>
EXPECTED

local $Plack::Middleware::BasicStyle::DEFAULT_STYLE = '<here>';

run_test [], $default_hdrs, <<'BODY', <<'EXPECTED', 'no head';
<html>
content
BODY
<html><here>
content
EXPECTED

run_test [], $default_hdrs, <<'BODY', <<'EXPECTED', 'no html';
<head>
content
BODY
<head><here>
content
EXPECTED

run_test [], $default_hdrs, 'content', '<here>content', 'no head, no html';

run_test [], $default_hdrs, '<!DOCTYPE html>', '<!DOCTYPE html><here>', 'just doctype';

run_test [], [], 'no change', 'no change', 'no content-type';

run_test [any_content_type => 1], [], 'yes change', '<here>yes change', 'no content-type + any_content_type';

run_test [], $default_hdrs, (<<'BODY') x 2, 'has <style>';
<!DOCTYPE html>
<head>
<style>h1 { color: red; }</style>
content
BODY

run_test [], $default_hdrs, (<<'BODY') x 2, 'has external stylesheet';
<!DOCTYPE html>
<html>>
<link href="/style.css" rel="stylesheet">
content
BODY

run_test [even_if_styled => 1], $default_hdrs,
  <<'BODY', <<'EXPECTED', 'has <style> + even_if_styled';
<!DOCTYPE html>
<style>h1 { color: red; }</style>
content
BODY
<!DOCTYPE html><here>
<style>h1 { color: red; }</style>
content
EXPECTED

run_test [style => '<there>'], $default_hdrs, 'content', '<there>content', 'style';

run_test [use_link_header => '/basic-style.css'],
  $default_hdrs, 'test', ['Link', '</basic-style.css>; rel=stylesheet'], 'use_link_header';

run_test [use_link_header => '/basic-style.css'],
  $default_hdrs, 'test', '<here>', 'use_link_header - /basic-style.css', '/basic-style.css';
