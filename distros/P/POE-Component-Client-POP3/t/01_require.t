#!/usr/bin/perl -w

use strict;
use Test;

BEGIN {
    plan tests => 2;
    ok( sub { eval 'use POE'; $@ }, '' );
    ok( sub { eval 'use POE::Component::Client::POP3'; $@ }, '' );
}

