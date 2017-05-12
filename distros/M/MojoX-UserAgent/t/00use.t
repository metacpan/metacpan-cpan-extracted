#!/usr/bin/env perl

use Test::More tests => 3;

BEGIN {
use_ok( 'MojoX::UserAgent::Transaction' );
use_ok( 'MojoX::UserAgent::CookieJar' );
use_ok( 'MojoX::UserAgent' );
}

