#!/usr/bin/perl

# Simple PSGI application

use strict;
use warnings;

sub {
    [
        200, ['Content-Type' => 'text/html'],
        ['<!DOCTYPE html><html><head><title>Hello, world!</title></head><body>Hello, world!</body></html>']
    ]
};
