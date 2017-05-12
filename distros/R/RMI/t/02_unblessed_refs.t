#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 32;
use FindBin;
use lib $FindBin::Bin;
use RMI::TestClass2;

use_ok("RMI::Client::ForkedPipes");

my $c = RMI::Client::ForkedPipes->new();
ok($c, "created an RMI::Client::ForkedPipes using the default constructor (fored process with a pair of pipes connected to it)");

note("make a remote object");
my $remote1 = $c->call_class_method('RMI::TestClass2', 'new', name => 'remote1');
ok($remote1, "got an object");

###################

note("test returned non-object references: ARRAY");

my $a = $remote1->create_and_return_arrayref(one => 111, two => 222);
isa_ok($a,"ARRAY", "object $a is an ARRAY");

my @a = eval { @$a; };
ok(!$@, "treated returned value as an arrayref");
is("@a", "one 111 two 222", " content is as expected");

my $a2 = $remote1->last_arrayref;
is($a2,$a, "2nd copy of arrayref $a2 from the remote side matches he first $a");

push @$a, three => 333;
is($a->[4],"three", "successfully mutated array with push");
is($a->[5],"333", "successfully mutated array with push");
is($remote1->last_arrayref_as_string(), "one:111:two:222:three:333", " contents on the remote side match");

$a->[3] = '2222';
is($a->[3],'2222',"updated one value in the array");
is($remote1->last_arrayref_as_string(), "one:111:two:2222:three:333", " contents on the remote side match");

my $v2 = pop @$a;
is($v2,'333',"pop works");
my $v1 = pop @$a;
is($v1,'three',"pop works again");
is($remote1->last_arrayref_as_string(), "one:111:two:2222", " contents on the remote side match");

eval { @$a = (11,22) };
ok(!$@, "reset of the array contents works (preivously a bug b/c Tie::StdArray has no implementation of EXTEND.")
    or diag($@);


###################

note("test returned non-object references: HASH");

my $h = $remote1->create_and_return_hashref(one => 111, two => 222);
isa_ok($h,"HASH", "object $h is a HASH");

my @h = eval { %$h; };
ok(!$@, "treated returned value as an hashref");
is("@h", "one 111 two 222", " content is as expected");

$h->{three} = 333;
is($h->{three},333,"key addition");

$h->{two} = 2222;
is($h->{two},2222,"key change works");

ok(exists($h->{one}), "key exists before deletion");
my $v = delete $h->{one};
is($v,111,"value returns from deletion");
ok(!exists($h->{one}), "key is gone after deletion");

is($remote1->last_hashref_as_string(), "three:333:two:2222", " contents on the remote side match");

###################

note("test returned non-object references: SCALAR");

my $s = $remote1->create_and_return_scalarref("hello");
isa_ok($s,"SCALAR", "object $h is a SCALAR");
my $v3 = $$s;
is($v3,"hello", "scalar ref returns correct value");
$$s = "goodbye";
my $v4 = $remote1->last_scalarref_as_string();
is($v4,"goodbye","value of scalar on remote side is correct");

###################

note("test returned non-object references: CODE");

my $x = $remote1->create_and_return_coderef('sub { $r = $$; return join(":",$r,@_); }');
isa_ok($x,"CODE", "object $h is a CODE reference");
my $v5 = $x->();
is($v5, $c->peer_pid, "value returned is as expected");
my $v6 = $x->('a','b','c');
is($v6, $c->peer_pid . ":a:b:c", "value returned from second call is as expected");
$x = undef;

note("Test passing code refs");
my @a1 = (11,22,33);
my $sub1 = sub {
    for (@a1) {
        $_ *= 2;
    }
};
$remote1->call_my_sub($sub1);
is_deeply(\@a1,[22,44,66], "remote server called back local sub and modified closure variables");

###################

note("closing connection");
$c->close;
note("exiting");
exit;
