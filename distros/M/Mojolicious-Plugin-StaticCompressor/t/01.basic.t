# Test for basic use of StaticCompressor
use strict;
use warnings;

use Test::More tests => 21;
use Test::Mojo;
use FindBin;
use File::Slurp;
use CSS::Minifier qw();
use JavaScript::Minifier qw();

# Prepare a test app with Plugin
use Mojolicious::Lite;
plugin('StaticCompressor');

get '/foo' => sub {
	# HTML page (include single js) - t/templates/foo.html.ep
	my $self = shift;
	$self->render;
};

get '/foobar' => sub {
	# HTML page (include multiple js) - t/templates/foobar.html.ep
	my $self = shift;
	$self->render;
};

get '/baz' => sub {
	# HTML page (include single css) - t/templates/baz.html.ep
	my $self = shift;
	$self->render;
};


# Test for HTML-tag (script tag, single compressed-file)
my $t = Test::Mojo->new;
$t->get_ok('/foo')->status_is(200)->content_like(qr/<script src="(.+)"><\/script>/);
$t->tx->res->body =~ /<script src="(\/auto_compressed\/.+)"><\/script>/;
my $script_path = $1;
# Test for script (single compressed js)
$t->get_ok($script_path)->status_is(200)->content_type_like(qr/application\/javascript\.*/)
	->content_is( JavaScript::Minifier::minify(input => File::Slurp::read_file("$FindBin::Bin/public/js/foo.js") ."") );

# Test for HTML-tag (script tag, multiple compressed-file)
$t->get_ok('/foobar')->status_is(200)->content_like(qr/<script src="(.+)"><\/script>/);
$t->tx->res->body =~ /<script src="(\/auto_compressed\/.+)"><\/script>/;
$script_path = $1;

# Test for script (multiple compressed js)
$t->get_ok($script_path)->status_is(200)->content_type_like(qr/application\/javascript\.*/)
	->content_is(
		JavaScript::Minifier::minify(input => File::Slurp::read_file("$FindBin::Bin/public/js/foo.js") ."")
		. JavaScript::Minifier::minify(input => File::Slurp::read_file("$FindBin::Bin/public/js/bar.js") ."")
	);


# Test for HTML-tag (link-rel tag, single compressed-file)
$t = Test::Mojo->new;
$t->get_ok('/baz')->status_is(200)->content_like(qr/<link rel="stylesheet" href="\/auto_compressed\/.+">/);
$t->tx->res->body =~ /<link rel="stylesheet" href="(\/auto_compressed\/.+)">/;
my $css_path = $1;

# Test for script (single compressed css)
$t->get_ok($css_path)->status_is(200)->content_type_like(qr/text\/css\.*/)
	->content_is( CSS::Minifier::minify(input => File::Slurp::read_file("$FindBin::Bin/public/css/baz.css") ."") );
=cut
