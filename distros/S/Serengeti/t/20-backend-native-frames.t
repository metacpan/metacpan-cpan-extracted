#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Response;
use JavaScript;

use Test::More qw(no_plan);
use Test::Exception;

BEGIN { use_ok("Serengeti::Backend::Native::Document"); }

use Serengeti::Backend::Native;

my $source = <<'__END_OF_HTML__';
<html>
<frameset cols="20%,80%">
  <frame name="left" src="t/data/20-frame-left.html">
  <frameset rows="85%,15%" id="subframeset">
    <frame name="top" src="t/data/20-frame-top.html">
    <frame name="bottom" src="t/data/20-frame-bottom.html">
  </frameset>
</frameset>
</html>
__END_OF_HTML__

my $document = Serengeti::Backend::Native::Document->new($source);

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();

Serengeti::Backend::Native->setup_document_jsapi($cx);

$cx->bind_function(diag => sub { diag @_ });
$cx->bind_function(ok => sub { ok(shift, shift) });
$cx->bind_function(is => sub { is(shift, shift, shift) });

$cx->eval(<<'__END_OF_JS__');
function test_frameset(document) {
    var frameset = document.body;
    is(frameset.tagName, "frameset");
    
    is(frameset.cols, "20%,80%");
    
    var subframeset = document.getElementById("subframeset");
    is(subframeset.rows, "85%,15%");
    
    var frame = frameset.find('.//frame[@name="top"]');
}

__END_OF_JS__
diag $@ if $@;

$cx->call("test_frameset", $document);
diag $@ if $@;

