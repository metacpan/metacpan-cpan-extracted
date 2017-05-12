#!/usr/bin/perl

use strict;
use warnings;

use JavaScript;

use Test::More qw(no_plan);
use Test::Exception;

BEGIN { use_ok("Serengeti::Backend::Native::Document"); }

use Serengeti::Backend::Native;

my $source = <<'__END_OF_HTML__';
<html>
<head>
    <title>Test document</title>
</head>
<BODY id="bodyElement">
    <div class="foo">
        Test div
    </div>
    <div class="bar"/>
    <a id="loginLink" href="http://localhost/login">Login</a>
    <a name="anchor1">Anchor 1</a>
    <a id="anchor2">Anchor 2</a>
    <br>
    <img src="./foo/bar.jpg" alt="foobar image">
</body>
</html>
__END_OF_HTML__

my $document = Serengeti::Backend::Native::Document->new(
    $source, 
    { 
        location => "http://localhost/foo/bar?quax=true#a452",
        referrer => "http://localhost/",
    }
);

isa_ok($document, "Serengeti::Backend::Native::Document");

my $e = $document->find("div.foo");
is(scalar @$e, 1);
is($e->[0]->as_trimmed_text, "Test div");

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();

lives_ok {
    Serengeti::Backend::Native->setup_document_jsapi($cx);
};

$cx->bind_function(diag => sub { diag @_ });
$cx->bind_function(ok => sub { ok(shift, shift) });
$cx->bind_function(is => sub { is(shift, shift, shift) });

$cx->eval(<<'__END_OF_JS__');
function test_document(document) {
    /* DOM Level 0 */
    is(document.location.hash, "#a452");
    is(document.location.host, "localhost:80");
    is(document.location.hostname, "localhost");
    is(document.location.href, "http://localhost/foo/bar?quax=true#a452");
    is(document.location.pathname, "/foo/bar");
    
    /* DOM Level 1 */
    ok(!document.doctype); // NOT SUPPORTED
    ok(!document.implementation); // NOT SUPPORTED
    ok(document.documentElement);
    
    is(document.URL, "http://localhost/foo/bar?quax=true#a452");
    is(document.title, "Test document");
    is(document.referrer, "http://localhost/");
    is(document.domain, "localhost");
    is(document.body.id, "bodyElement");
    
    ok(document.images);
    is(document.images.length, 1);
    is(document.images[0].src, "./foo/bar.jpg");
    is(document.images[0].alt, "foobar image");
    
    
    ok(!document.applets); // NOT SUPPORTED
    ok(document.links);
    is(document.links.length, 1);
    is(document.links[0].href, "http://localhost/login");
    
    ok(document.forms); // NOT SUPPORTED

    ok(document.anchors);
    is(document.anchors.length, 1);
    is(document.anchors[0].name, "anchor1");
    
    var list = document.getElementsByTagName("div");
    is(list.length, 2);
    
    var loginLink = document.getElementById("loginLink");
    ok(loginLink);
    
    /* Test find method and NodeList class */
    var nodes = document.find("div.foo");
    is(nodes.length, 1);
    var elem_by_index = nodes[0];
    var elem = nodes.item(0);
    is(elem, elem_by_index);
    ok(elem.innerHTML.match(/<div class="foo">\s*Test div\s*<\/div>/));
    is(elem.textValue, "Test div");
    is(elem.getAttribute("class"), "foo");
}
__END_OF_JS__
diag $@ if $@;

$cx->call("test_document", $document);
diag $@ if $@;
