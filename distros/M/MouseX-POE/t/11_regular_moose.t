#!/usr/bin/env perl
use strict;

use Test::More tests => 1;

{
    package Foo;
    use MouseX::POE;

    package Bar;
    use Mouse;
    has a => ( is => 'ro' );
}

ok(!exists Bar->new( a => 1)->{session_id}, 'no session_id');
