#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use lib "t/files";

undef $@;
eval { require "parse_error" };
ok( $@, "template parse errors are fatal" );
like( $@, qr/parse error/, "error is correct" );

undef $@;
eval { require "undef_var" };
ok( $@, "undef vars die" );
like( $@, qr/undef error/, "error is correct" );

undef $@;
eval { require "undef_ok" };
ok( !$@, "undef vars don't die if you override the DEBUG attr" );

