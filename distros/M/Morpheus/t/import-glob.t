#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use lib 'lib';
use Morpheus -defaults => {
    "test/import/collision" => do {
        no strict;
        package Defaults;
        @x = (1, 2); %x = (a => "b");
        @y = (1,2,3); $y = "a";
        { x => \*x, y => \*y}
    },
};

is_deeply(scalar(eval(q#package X1; use Morpheus "test/import/collision" => [qw(@x)]; [@x]#)), [1,2], "@/% collision => @");
is_deeply(scalar(eval(q#package X2; use Morpheus "test/import/collision" => [qw(%x)]; return {%x}#)), {a=>"b"}, "@/% collision => %");
throws_ok(sub{ eval(q#package X3; use Morpheus "test/import/collision" => [qw($x)];#); die if $@}, qr/not defined/, "@/% collition => \$");

is_deeply(scalar(eval(q#package X4; use Morpheus "test/import/collision" => [qw(@y)]; [@y]#)), [1,2,3], "@/\$ collision => @");
is(scalar(eval(q#package X5; use Morpheus "test/import/collision" => [qw($y)]; $y#)), "a", "@/\$ collision => \$");
throws_ok(sub{ eval(q#package X6; use Morpheus "test/import/collision" => [qw(%y)];#); die if $@}, qr/not defined/, "@/\$ collision => %");

