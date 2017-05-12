#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;
use FindBin;
use lib $FindBin::Bin;
use Data::Dumper;
use RMI::Client::ForkedPipes;

package Test1;

sub echo {
    return shift;
}

package main;

my $c = RMI::Client::ForkedPipes->new();
ok($c, "created a test client/server pair");

my $o1 = bless({},"Foo");
my $o2 = $c->call_function('Test1::echo', $o1);
is($o2,$o1, "the returned object is the same as the sent one");

my $h1 = { foo => 111 };
my $h2 = $c->call_function('Test1::echo',$h1);
is($h2, $h1, "the returned reference si the same as the sent one");

my $o3 = $c->call_function('Test1::echo', $o1);
is($o2,$o1, "the returned object is the same as the sent one");

my $h3 = $c->call_function('Test1::echo',$h1);
is($h3, $h1, "the returned reference si the same as the sent one");

