#!/usr/bin/perl

use strict;
use warnings;

use JavaScript;

use Test::More qw(no_plan);
use Test::Exception;

use Serengeti::Backend::Native;

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();

Serengeti::Backend::Native->setup_document_jsapi($cx);

$cx->bind_function(diag => sub { diag @_ });
$cx->bind_function(ok => sub { ok(shift, shift) });
$cx->bind_function(is => sub { is(shift, shift, shift) });

my $element = HTML::Element->new(
    "link",
    charset => "iso-8859-1",
    href => "http://localhost/test.js",
    hreflang => "en-US",
    rel => "Stylesheet",
    rev => "Index",
    target => "mainFrame",
    type => "text/css",
    
);

$cx->eval(<<'__END_OF_JS__');
function test_HTMLLinkElement(element) {
    is(element.disabled, false);
    is(element.charset, "iso-8859-1");
    is(element.href, "http://localhost/test.js");
    is(element.hreflang, "en-US");
    is(element.rel, "Stylesheet");
    is(element.rev, "Index");
    is(element.target, "mainFrame");
    is(element.type, "text/css");
    is(element.media, "screen"); // defaults to "screen"
}
__END_OF_JS__
diag $@ if $@;

$cx->call("test_HTMLLinkElement", $element);
diag $@ if $@;
