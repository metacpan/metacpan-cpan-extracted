#!/usr/bin/perl

##
## Tests for OpenFrame::WebApp::Segment::Session::CookieLoader
##

use blib;
use strict;
use warnings;

use Test::More no_plan => 1;

use Error qw( :try );
use OpenFrame::Cookie;
use OpenFrame::Cookies;
use Pipeline::Segment::Tester;

BEGIN { use_ok("OpenFrame::WebApp::Session::Factory"); }
BEGIN { use_ok("OpenFrame::WebApp::Session::MemCache"); }
BEGIN { use_ok("OpenFrame::WebApp::Segment::Session::CookieLoader"); }

my $sl_seg = new OpenFrame::WebApp::Segment::Session::CookieLoader;
ok( $sl_seg, "new" ) || die( "can't create new object!" );

my $pt       = new Pipeline::Segment::Tester;
my $sfactory = new OpenFrame::WebApp::Session::Factory()->type('mem_cache');
my $prod     = $pt->test( $sl_seg, $sfactory );

my $session  = $pt->pipe->store->get('OpenFrame::WebApp::Session::MemCache');
if (ok( $session, 'session found in store' )) {
    $session->remove;
}

my $ctin = $pt->pipe->store->get('OpenFrame::Cookies');
my $name = $OpenFrame::WebApp::Segment::Session::CookieLoader::COOKIE_NAME;
if (ok( $ctin, 'cookie tin found in store' )) {
    my $cookie = $ctin->get($name);
    if (ok( $cookie, 'session cookie found' ) && defined($session)) {
	is( $cookie->value, $session->id, 'ids match' );
    }
}

