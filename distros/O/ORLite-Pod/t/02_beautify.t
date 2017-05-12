#!/usr/bin/perl

# Tests the beautification of SQL

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 1;
use ORLite::Pod ();

# Simple test
is( ORLite::Pod->beautify(<<'END_INPUT'), <<'END_OUTPUT', 'ORLite::Pod->beautify() works' );
CREATE TABLE settings (id           INTEGER PRIMARY KEY,                    name         TEXT NOT NULL)
END_INPUT
CREATE TABLE settings (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
)
END_OUTPUT
