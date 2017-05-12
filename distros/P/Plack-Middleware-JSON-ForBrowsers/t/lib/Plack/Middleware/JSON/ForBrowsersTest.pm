package Plack::Middleware::JSON::ForBrowsersTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Test::More;
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common;
use Encode;

my $original_data = encode('UTF-8', "{\"foo\":\"bar, \x{263a}, \x{fc}\",\"<h1>baz</h1>\":2}");

sub startup : Test(startup) {
	my ($self) = @_;
	$self->{app} = Plack::Util::load_psgi('examples/app.psgi');
}


sub basic_test : Test(12) {
	my ($self) = @_;

	test_psgi $self->{app}, sub {
		my ($cb) = @_;

		my $res = $cb->(GET "/json", 'Accept' => 'text/html');
		is($res->header('content-type'), 'text/html; charset=utf-8', 'content type changed');
		like($res->content(), qr{<html}, 'response contains HTML');
		like($res->content(), qr{&#x263A;}, 'WHITE SMILING FACE encoded');
		like($res->content(), qr{&#xFC;}, 'LATIN SMALL LETTER U WITH DIAERESIS encoded');
		like($res->content(), qr{&#x3C;}, 'LESS-THAN SIGN encoded');
		like($res->content(), qr{&#x3E;}, 'GREATER-THAN SIGN encoded');

		$res = $cb->(GET "/json");
		is($res->header('content-type'), 'application/json', 'content type not changed');
		is($res->content(), $original_data, 'response not modified');

		$res = $cb->(GET "/json", 'X-Requested-With' => 'XMLHttpRequest');
		is($res->header('content-type'), 'application/json', 'content type not changed');
		is($res->content(), $original_data, 'response not modified');

		$res = $cb->(GET "/other");
		is($res->header('content-type'), 'text/plain', 'content type not changed');
		is($res->content(), 'Hello, world!', 'response not modified');
	};
}


sub looks_like_browser_request_test : Test(6) {
	my ($self) = @_;

	my $mw = Plack::Middleware::JSON::ForBrowsers->new({});

	is($mw->looks_like_browser_request({
		HTTP_ACCEPT => 'text/html'
	}), 1, 'accepts HTML, assume browser');

	is($mw->looks_like_browser_request({
		HTTP_ACCEPT => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
	}), 1, 'accepts HTML, assume browser');

	is($mw->looks_like_browser_request({}), 0, 'cannot tell, assume no browser');

	is($mw->looks_like_browser_request({
		HTTP_X_REQUESTED_WITH => 'XMLHttpRequest'
	}), 0, 'XMLHttpRequest, no browser');

	is($mw->looks_like_browser_request({
		HTTP_ACCEPT           => 'text/html,application/xhtml+xml',
		HTTP_X_REQUESTED_WITH => 'XMLHttpRequest'
	}), 0, 'XMLHttpRequest, no browser');

	is($mw->looks_like_browser_request({
		HTTP_ACCEPT => 'application/json',
	}), 0, 'only json, no browser');
}


sub json_to_html_test : Test(5) {
	my ($self) = @_;

	my $mw = Plack::Middleware::JSON::ForBrowsers->new({});
	my $html = $mw->json_to_html($original_data);

	like($html, qr{<html}, 'response contains HTML');
	like($html, qr{&#x263A;}, 'WHITE SMILING FACE encoded');
	like($html, qr{&#xFC;}, 'LATIN SMALL LETTER U WITH DIAERESIS encoded');
	like($html, qr{&#x3C;}, 'LESS-THAN SIGN encoded');
	like($html, qr{&#x3E;}, 'GREATER-THAN SIGN encoded');
}


sub custom_html_head_and_foot_test : Test(6) {
	my ($self) = @_;

	my $mw = Plack::Middleware::JSON::ForBrowsers->new({
		html_head => '',
		html_foot => '',
	});
	my $html = $mw->json_to_html('{}');
	is($html, "{}", 'empty head and foot appended');

	$mw = Plack::Middleware::JSON::ForBrowsers->new({
		html_head => 'head',
		html_foot => 'foot',
	});
	$html = $mw->json_to_html('{}');
	is($html, "head{}foot", 'no head or foot appended');

	$mw = Plack::Middleware::JSON::ForBrowsers->new({
		html_head => 'head',
	});
	$html = $mw->json_to_html('{}');
	like($html, qr{head\{\}</code>}, 'custom html head');

	$mw = Plack::Middleware::JSON::ForBrowsers->new({
		html_foot => 'foot',
	});
	$html = $mw->json_to_html('{}');
	like($html, qr{<code>\{\}foot}, 'custom html foot');

	$mw = Plack::Middleware::JSON::ForBrowsers->new({
		html_head => "\x{263a}",
		html_foot => "\x{263b}",
	});
	$html = $mw->json_to_html('{}');
	is($html, encode('UTF-8', "\x{263a}{}\x{263b}"), 'UTF-8 in head and foot');
}


1;
