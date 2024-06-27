#!/usr/bin/env perl
use strict;
use Test::More;

BEGIN {
    use_ok('Raylib::FFI');
}

diag("Testing Raylib::FFI $Raylib::FFI::VERSION, Perl $], $^X");

done_testing;
