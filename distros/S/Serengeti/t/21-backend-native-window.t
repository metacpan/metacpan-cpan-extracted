#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;

use Test::More qw(no_plan);
use Test::Exception;

use Serengeti;

my $source = <<'__END_OF_HTML__';
__END_OF_HTML__

my $browser = Serengeti->new({backend => "Native"});

$browser->context->js_ctx->bind_function(diag => sub { diag @_ });
$browser->context->js_ctx->bind_function(ok => sub { ok(shift, shift) });
$browser->context->js_ctx->bind_function(is => sub { is(shift, shift, shift) });
$browser->context->js_ctx->bind_function(like => sub { like(shift, shift, shift) });

my $me = File::Spec->rel2abs(__FILE__);
my $datafile = File::Spec->catfile("data","21-frameset.html");

$me =~ s/21-backend-native-window\.t/$datafile/;
$browser->context->js_ctx->bind_value(test_file => "file://$me");

$browser->eval(<<'__END_OF_JS__');
    ok(window);
    is(window.closed, 0);
    is(window.location.href, "about:blank");
    
    $Browser.get(test_file);
    
    is(window.location.href, test_file);
    
    is(window.frames.length, 3);
    like(window.frames["frame1"].src, /frame1\.html$/);
    
    var d = window.frames["frame1"].contentDocument;
    ok(document != d);
__END_OF_JS__
fail $@ if $@;

