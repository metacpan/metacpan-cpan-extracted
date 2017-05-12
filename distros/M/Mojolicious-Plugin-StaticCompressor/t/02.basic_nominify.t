# Test for StaticCompressor js_nominify, css_nominify
use strict;
use warnings;

use Test::More tests => 12;
use Test::Mojo;
use FindBin;
use File::Slurp;

# Prepare a test app with Plugin
use Mojolicious::Lite;
plugin('StaticCompressor');

get '/foo_nominify' => sub {
	# HTML page (include single js)
	my $self = shift;
	$self->render;
};

get '/foobar_nominify' => sub {
	# HTML page (include multiple js)
	my $self = shift;
	$self->render;
};


# Test for HTML-tag (script tag, single compressed-file)
my $t = Test::Mojo->new;
$t->get_ok('/foo_nominify')->status_is(200)->content_like(qr/<script src="(.+)"><\/script>/);
$t->tx->res->body =~ /<script src="(\/auto_compressed\/.+)"><\/script>/;
my $script_path = $1;

# Test for script (single compressed js, but not minified. Actually, SAME as raw file.) 
$t->get_ok($script_path)->status_is(200)->content_is( File::Slurp::read_file("$FindBin::Bin/public/js/foo.js")."" );


# Test for HTML-tag (script tag, multiple compressed-file)
$t->get_ok('/foobar_nominify')->status_is(200)->content_like(qr/<script src="(.+)"><\/script>/);
$t->tx->res->body =~ /<script src="(\/auto_compressed\/.+)"><\/script>/;
$script_path = $1;

# Test for script (multiple compressed js, but not minified)
$t->get_ok($script_path)->status_is(200)->content_is(
	File::Slurp::read_file("$FindBin::Bin/public/js/foo.js")
	. File::Slurp::read_file("$FindBin::Bin/public/js/bar.js")
);
