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
    "base",
    href => "http://localhost/",
    target => "dynamic",
);

$cx->eval(<<'__END_OF_JS__');
function test_HTMLBaseElement(element) {
    is(element.href, "http://localhost/");
    is(element.target, "dynamic");
}
__END_OF_JS__
diag $@ if $@;

$cx->call("test_HTMLBaseElement", $element);
diag $@ if $@;
