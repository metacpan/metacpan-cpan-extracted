#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 9;
use FindBin;
use lib $FindBin::Bin;
use RMI::TestClass2;

sub local_exception { die 'local exception'; }

use_ok("RMI::Client::ForkedPipes");
my $c = RMI::Client::ForkedPipes->new();
ok($c, "created an RMI::Client::ForkedPipes using the default constructor (fored process with a pair of pipes connected to it)");

my $remote1 = $c->call_class_method('RMI::TestClass2', 'new', name => 'remote1');
ok($remote1, "got a remote object");

my @a = $remote1->increment_array(11,22,33);
is_deeply(\@a, [12,23,34], "got back the expecte array in array context");

my $s = $remote1->increment_array(11,22,33);
is($s,3, "got back the count in scalar context");

$remote1->remember_wantarray;
is($remote1->return_last_wantarray, undef, "wantarray is undef when no retval is expected");

$s = $remote1->remember_wantarray;
is($remote1->return_last_wantarray, '', "wantarray is undef when a scalar is expected");

@a =  $remote1->remember_wantarray;
is($remote1->return_last_wantarray, '1', "wantarray is 1 when no an array expected");


ok($c->close, "closed the client connection");
exit;
