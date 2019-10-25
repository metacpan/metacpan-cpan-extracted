#!perl

use strict;
use warnings;
use Test::More 0.98;

use String::Elide::Tiny qw(elide);

is(elide("1234567890",  2), "..");
is(elide("1234567890", 12), "1234567890");
is(elide("1234567890", 10), "1234567890");
is(elide("1234567890",  6), "123...");

# opt: marker
is(elide("1234567890",  1, {marker=>"-"}), "-");
is(elide("1234567890",  2, {marker=>"-"}), "1-");
is(elide("1234567890", 12, {marker=>"-"}), "1234567890");
is(elide("1234567890", 10, {marker=>"-"}), "1234567890");
is(elide("1234567890",  6, {marker=>"-"}), "12345-");

# opt: truncate=left
is(elide("1234567890", 10, {truncate=>"left"}), "1234567890");
is(elide("1234567890",  6, {truncate=>"left"}), "...890");

# opt: truncate=middle
is(elide("1234567890", 10, {truncate=>"middle"}), "1234567890");
is(elide("1234567890",  7, {truncate=>"middle"}), "12...90");
is(elide("1234567890",  6, {truncate=>"middle"}), "1...90");

# opt: truncate=ends
is(elide("1234567890", 10, {truncate=>"ends"}), "1234567890");
is(elide("1234567890",  7, {truncate=>"ends"}), "...5...");
is(elide("1234567890",  6, {truncate=>"ends"}), "......");

done_testing;
