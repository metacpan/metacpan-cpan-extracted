#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 13;
use FindBin;
use lib $FindBin::Bin;
use IO::File;

# $c = RMI::Client::ForkedPipes->new();
# $c->use_remote("DBI");
#
# $c = DBI->connect(); # DBI is not really here...

my @matches;

use_ok("RMI::Client::ForkedPipes");
my $c = RMI::Client::ForkedPipes->new();
ok($c, "created an RMI::Client::ForkedPipes using the default constructor (fored process with a pair of pipes connected to it)");

ok(!RMI::TestClass1->can("new"), "test class has NOT been used before we proxy it");

$c->use_lib_remote;
#eval "use lib \$c->virtual_lib";
ok(!$@, 'added a virtual lib to the @INC list which will make all attempts to use modules auto-proxy.');

use_ok("RMI::TestClass1", "used RMI:TestClass1");

my $remote2 = RMI::TestClass1->new(name => 'remote2');
ok($remote2, "created a remote object using regular/local syntax");
is(ref($remote2),'RMI::TestClass1', "real class on remote object is returned as the expected name");
isa_ok($remote2,"RMI::TestClass1", "isa returns true when used with the proxied class");

is($remote2->m1, $c->peer_pid, "object method returns a value indicating it ran in the other process");
ok($remote2->m1 != $$, "object method returns a value indicating it did not run in this process");

use_ok("Sys::Hostname");
ok(Sys::Hostname::hostname(), "got hostname");

ok($c->close, "closed the client connection");
exit;
