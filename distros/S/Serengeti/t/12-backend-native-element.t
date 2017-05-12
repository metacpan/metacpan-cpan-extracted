#!/usr/bin/perl

use strict;
use warnings;

use JavaScript;

use Test::More qw(no_plan);
use Test::Exception;

use Serengeti::Backend::Native;

my $source = <<'__END_OF_HTML__';
<html>
<body>
    <div id="testDiv">
        <h1 id="testH1"></h1>
        <span id="testSpan" title="testTitle" 
              lang="en-US" dir="LTR" class="testClass">
              Text content
        </span>
    </div>
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

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();

Serengeti::Backend::Native->setup_document_jsapi($cx);

$cx->bind_function(diag => sub { diag @_ });
$cx->bind_function(ok => sub { ok(shift, shift) });
$cx->bind_function(is => sub { is(shift, shift, shift) });

my $element = $document->find_first("#testSpan");

$cx->eval(<<'__END_OF_JS__');
function test_HTMLElement(element, document) {
    is(element.id, "testSpan", "id");
    is(element.title, "testTitle", "title");
    is(element.lang, "en-US", "lang");
    is(element.dir, "LTR", "dir");
    is(element.className, "testClass", "className");

    is(element.parentNode.id, "testDiv", "parentNode");

    ok(element.parentNode.hasChildNodes(), "Has child nodes");
    is(element.parentNode.childNodes.length, 2, "Has two children");
    is(element.parentNode.firstChild.id, "testH1", "firstChild");
    is(element.parentNode.lastChild.id, "testSpan", "lastChild");
    is(element.previousSibling.id, "testH1", "previousSibling");
    is(element.previousSibling.nextSibling.id, "testSpan", "nextSibling");
    
    is(element.ownerDocument, document, "ownerDocument");
}
__END_OF_JS__
diag $@ if $@;

$cx->call("test_HTMLElement", $element, $document);
diag $@ if $@;
