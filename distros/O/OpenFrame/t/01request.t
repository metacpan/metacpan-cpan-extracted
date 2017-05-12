#!/usr/bin/perl

use strict;
use warnings;

## test framework
use Test::Simple tests => 15;

## testing...
use URI;
use OpenFrame::Cookies;
use OpenFrame::Request;

my $URI  = URI->new( 'http://opensource.fotango.com/' );
my $args = { test => 'true' };

## generic tests
ok(1,"cookies, request, and uri loaded okay");

## cookie tests
ok(my $cookie = OpenFrame::Cookies->new(), "created cookietin okay");
ok($cookie->set(colour => "red"), "set cookie okay");
ok($cookie->get("colour")->value eq 'red', "got cookie okay");
my $real = $cookie->get("colour");
use Data::Dumper; print Dumper( $real );
print $real->value(), "\n";

ok({$cookie->get_all()}->{"colour"}->value eq 'red', "get_all worked okay");
ok($cookie->delete( "colour" ), "deleted okay");
ok(!exists {$cookie->get_all()}->{colour}, "definitly deleted okay");
ok($cookie->set("test" => "true"), "set test cookie okay");

## request tests
ok(my $req = OpenFrame::Request->new(), "created request okay");
ok($req->uri( $URI ), "set uri okay");
ok($req->uri()->host() eq 'opensource.fotango.com', "got uri okay");
ok($req->arguments( $args ), "set arguments okay");
ok($req->arguments->{test} eq 'true', "got arguments okay");
ok($req->cookies( $cookie ), "set cookies okay");
ok($req->cookies()->get("test")->value eq 'true', "got cookies okay");

