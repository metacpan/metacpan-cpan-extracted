# Test for disable_on_devmode
use strict;
use warnings;

use Test::More tests => 9;
use Test::Mojo;

# Prepare a test app with Plugin
use Mojolicious::Lite;
plugin('StaticCompressor', disable_on_devmode => 1);

app->mode('development');

get '/foo' => sub {
	# HTML page (include single js)
	my $self = shift;
	$self->render;
};

get '/foobar' => sub {
	# HTML page (include multiple js)
	my $self = shift;
	$self->render;
};

get '/baz' => sub {
	# HTML page (include single css)
	my $self = shift;
	$self->render;
};


# Test for HTML-tag (script tag, but NOT compressed-file)
my $t = Test::Mojo->new;
$t->get_ok('/foo')->status_is(200)->content_like(qr/<script src="\/js\/foo.js"><\/script>/);


# Test for HTML-tag (double script tag, but NOT compressed-file)
$t->get_ok('/foobar')->status_is(200)->content_like(qr/<script src="\/js\/foo.js"><\/script>\n<script src="\/js\/bar.js"><\/script>/);


# Test for HTML-tag (link-rel tag, but NOT compressed-file)
$t->get_ok('/baz')->status_is(200)->content_like(qr/<link rel="stylesheet" href="\/css\/baz.css">/);

