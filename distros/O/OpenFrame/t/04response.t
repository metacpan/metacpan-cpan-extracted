#!/usr/bin/perl

use strict;
use warnings;

## test framework
use Test::Simple tests => 20;

## testing...
use OpenFrame::Cookies;
use OpenFrame::Response;


## generic tests
ok(1,"cookies, request, and uri loaded okay");

## cookie tests
ok(my $cookie = OpenFrame::Cookies->new(), "created cookietin okay");
ok($cookie->set("test" => "true"), "set test cookie okay");

## request tests
ok(my $res = OpenFrame::Response->new(), "created request okay");
ok($res->cookies( $cookie ), "set cookies okay");
ok($res->cookies()->get("test")->value eq 'true', "got cookies okay");

ok($res->code(ofOK), "Set code");
ok($res->code() == ofOK, "Get code");
ok($res->code(ofERROR), "Set code");
ok($res->code() == ofERROR, "Get code");
ok($res->code(ofREDIRECT), "Set code");
ok($res->code() == ofREDIRECT, "Get code");
ok($res->code(ofDECLINE), "Set code");
ok($res->code() == ofDECLINE, "Get code");

ok($res->mimetype('text/html'), "Set mime type");
ok($res->mimetype() eq 'text/html', "Get mime type");

ok($res->message("hello world"), "Set message");
ok($res->message() eq 'hello world', "Get message");
ok($res->message(\"hello world"), "Set message as scalar ref");
ok($res->message() eq 'hello world', "Get message");
