use Mojo::Base -strict;

use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

plugin 'LinkedContent::v9';

my $lc = Mojolicious::Plugin::LinkedContent::v9->new;
# to add when we develop this module in mojolicious > 8.23
# $t->test('isa_ok', $lc, 'Mojolicious::Plugin::LinkedContent::v9');
#
# my $helpers = app->renderer->helpers;
#
# $t->test('isa_ok', $helpers->{require_js},  'CODE');
# $t->test('isa_ok', $helpers->{require_css}, 'CODE');
# $t->test('isa_ok', $helpers->{include_css}, 'CODE');
# $t->test('isa_ok', $helpers->{include_js},  'CODE');

foreach (qw/rel_js rel_css abs_js abs_css abs_url_js abs_url_css/) {
    get "/$_" => sub {
        my $self = shift;
        $self->render($_);
    };
}

# Relative path
$t->get_ok('/rel_js')->status_is(200)
    ->content_is("<script src='/js/dummy.js'></script>\n\n");

$t->get_ok('/rel_css')->status_is(200)
    ->content_is("<link rel='stylesheet' type='text/css' media='screen' href='/css/dummy.css' />\n\n");

$t->get_ok('/abs_js')->status_is(200)
    ->content_is("<script src='/dummy.js'></script>\n\n");

$t->get_ok('/abs_css')->status_is(200)
    ->content_is("<link rel='stylesheet' type='text/css' media='screen' href='/dummy.css' />\n\n");

$t->get_ok('/abs_url_js')->status_is(200)
    ->content_is("<script src='http://localhost/dummy.js'></script>\n\n");

$t->get_ok('/abs_url_css')->status_is(200)
    ->content_is("<link rel='stylesheet' type='text/css' media='screen' href='http://localhost/dummy.css' />\n\n");

done_testing();
__DATA__
@@ rel_js.html.ep
% require_js	'dummy.js';
%== include_js;

@@ rel_css.html.ep
% require_css	'dummy.css';
%== include_css;

@@ abs_js.html.ep
% require_js	'/dummy.js';
%== include_js;

@@ abs_css.html.ep
% require_css	'/dummy.css';
%== include_css;

@@ abs_url_js.html.ep
% require_js	'http://localhost/dummy.js';
%== include_js;

@@ abs_url_css.html.ep
% require_css	'http://localhost/dummy.css';
%== include_css;
