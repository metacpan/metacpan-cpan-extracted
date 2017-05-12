#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 8;
use FindBin;
use lib $FindBin::Bin;
use Data::Dumper;
use RMI::Client::ForkedPipes;

package Test1;

sub add_to_hash {
    my ($h, $k, $v) = @_;
    $h->{$k} = $v;
    return $h;
}

package Test2;

sub add_to_hash {
    my ($h, $k, $v) = @_;
    $h->{$k} = $v;
    return $h;
}

package main;

$RMI::ProxyObject::DEFAULT_OPTS{"Test2"}{"add_to_hash"} = { copy => 1 };

my $c = RMI::Client::ForkedPipes->new();
ok($c, "created a test client/server pair");

my $h1 = { foo => 111 };
ok($h1, "made a test hash");

my $h2 = $c->call_function('Test1::add_to_hash',$h1,'bar',222);
is($h2->{bar},222,"the key was added to the returned hash");
is($h1->{bar},222,"the key was added to the sent hash");
is($h2, $h1, "the hash passed-in is the same one which was returned");

my $h3 = $c->call_function('Test2::add_to_hash',$h1,'baz',333);
is($h3->{baz},333,"the key was added to the returned hash");
is($h1->{baz},undef,"the key was NOT added to the sent hash because we sent a copy");
ok($h3 != $h1, "the hash passed-in is NOT the same one which was returned");


