#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 84;
use FindBin;
use lib $FindBin::Bin;
use RMI::TestClass1;

use_ok("RMI::Client::ForkedPipes");
my $c = RMI::Client::ForkedPipes->new();
ok($c, "created an RMI::Client");


# check the count of objects sent and received after each call
my $sent = $c->_sent_objects;
my $received = $c->_received_objects;
sub expect_counts {
    my ($expected_sent, $expected_received) = @_;
    my $actual_sent = scalar(keys(%$sent));
    my $actual_received = scalar(keys(%$received));
    is($actual_sent, $expected_sent, "  count of sent objects $actual_sent is $expected_sent, as expected");
    is($actual_received, $expected_received, "  count of received objects $actual_received is $expected_received, as expected");    
    my ($remote_received) = $c->call_eval('scalar(keys(%{$RMI::executing_nodes[-1]->{_received_objects}}))');
    my ($remote_sent) = $c->call_eval('scalar(keys(%{$RMI::executing_nodes[-1]->{_sent_objects}}))');
    is($remote_received,$actual_sent, "  count of remote received objects $remote_received matches actual sent count $actual_sent");
    is($remote_sent,$actual_received, "  count of remote received objects $remote_sent matches actual sent count $actual_received");
}

my @result;
my $result;

note("basic remote function attempt 1");
@result = $c->call_function('main::f1', 2, 3); 
is($result[0], $c->peer_pid, "retval indicates the method was called in the child/server process");
is($result[1], 5, "result value $result[1] is as expected for 2 + 3");
expect_counts(0,0);

note("basic remote function attempt 2");
@result = $c->call_function('main::f1', 6, 7);
is($result[1], 13, "result value $result[1] is as expected for 6 + 7");  
expect_counts(0,0);

note("remote eval");
my $rpid = $c->call_eval('$$');
ok($rpid > $$, "got pid for other process: $rpid, which is > $$");
expect_counts(0,0);

note("local object call");
my $local1 = RMI::TestClass1->new(name => 'local1');
ok($local1, "made a local object");
$result = $local1->m1();
is($result, $$, "result value $result matches pid $$");  
expect_counts(0,0);

note("request that remote server do a method call on a local object, which just comes right back");
$result = $c->call_object_method($local1, 'm1');
ok(scalar($result), "called method remotely");
is($result, $$, "result value $result matches pid $$");  
expect_counts(0,0);

note("make a remote object");
my $remote1 = $c->call_class_method('RMI::TestClass1', 'new', name => 'remote1');
ok($remote1, "got an object");
print Data::Dumper::Dumper($remote1);
ok($remote1->isa('RMI::TestClass1'), "returned object isa() RMI:TestClass1 works") or diag(Data::Dumper::Dumper($remote1));
ok($remote1->UNIVERSAL::isa('RMI::ProxyObject'), "real class is the proxy (from UNIVERSAL::isa)") or diag(Data::Dumper::Dumper($remote1));
my @data = %$remote1;
note("@data");
expect_counts(0,1);

note("call methods on the remote object");

$result = $remote1->m2(8);
is($result, 16, "return values is as expected for remote object with primitive params");
expect_counts(0,1);

$result = $remote1->m3($local1);
is($result, $$, "return values are as expected for remote object with local object params");
expect_counts(0,1);

my $remote2 = $c->call_class_method('RMI::TestClass1', 'new', name => 'remote2');
ok($remote2, "made another remote object to use for a more complicated method call");
$result = $remote1->m3($remote2);
ok($result != $$, "return value is as expected for remote object with remote object params");
expect_counts(0,2);

$result = $remote1->m4($remote2,$local1);
is($result, "$rpid.$$.$$", "result $result has other process id, and this process id ($$) 2x");
expect_counts(0,2);


note("dereference local objects and ensure we pass along this to the other side");

is(scalar(@{$c->{_received_and_destroyed_ids}}), 0, "zero objects in queue to be be derefed on the other side");
expect_counts(0,2); # 2 objects from the remote end

$remote2 = undef;
is($remote2,undef,"got rid of reference to remote object #2");

is(scalar(@{$c->{_received_and_destroyed_ids}}), 1, "one object in queue to be be derefed on the other side");
ok($remote1->m1,"arbitrary method call made across the client to trigger sync of remote objects");
is(scalar(@{$c->{_received_and_destroyed_ids}}), 0, "zero objects in queue to be be derefed on the other side after a method call");

expect_counts(0,1); # 1 object from the remote end 


note("test holding references");

ok(!$c->_remote_has_ref($local1), "local object is not referenced on the other side before we pass it");
$remote1->dummy_accessor($local1);
ok($c->_remote_has_ref($local1), "local object is now referenced on the otehr side after passing to a method which retains it");
$remote1->dummy_accessor(undef);
ok(!$c->_remote_has_ref($local1), "remote reference is gone after telling the remote object to undef it");

note("can()");
my $ref = $remote1->can('m2');
ok($ref, "can() works with the remote object");
$result = $ref->($remote1,8);
is($result, 16, "return values the same when called via the remote CODE ref returned by can()");
expect_counts(0,2);
$ref = undef;
$remote1->m1(8);
expect_counts(0,2);

note("closing connection");
$c->close;
note("exiting");
exit;

# these may be called from the client or server
sub f1 {
    my ($v1,$v2) = @_;
    return($$, $v1+$v2);
}

sub f2 {
    my ($v1, $v2, $s, $r) = @_;
}

