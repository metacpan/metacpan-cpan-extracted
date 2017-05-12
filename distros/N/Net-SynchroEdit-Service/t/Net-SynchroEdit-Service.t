# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-SynchroEdit-Service.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 20;
BEGIN { use_ok('Net::SynchroEdit::Service') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Net::SynchroEdit::Service ':all';

# Test 2
my $obj = new Net::SynchroEdit::Service;
my $conn = $obj->connect;
if ($conn) {
    ok(1,                             "connect using defaults");
} else {
    ok(1,                             "connection to default response service indicates no service is running");
}
# ok($obj->connect,                     "connect using defaults (fails lest service runs @ localhost:7962)");

# Test 3
$obj  = new Net::SynchroEdit::Service;
$conn = $obj->connect("localhost", 7962);
if ($conn) {
    ok(1,                             "connect using arguments");
} else {
    ok(1,                             "connection using arguments indicates no service is running");
}

# Test 4
if ($conn) {
    ok($obj->query("QUERY"),          "service query");
} else {
    ok(1,                             "service query unavailable as no service is running");
}

# Test 5
if ($conn) {
    @qres = $obj->fetch_result;
    ok(defined @qres,                 "queried result fetch");
} else {
    ok(1,                             "queried result fetch unavailable as no service is running");
}

# Test 6
if ($conn) {
    $obj->query("INFO");
    my %result = $obj->fetch_map;
    ok(%result,                       "queried result fetch (as map)");
} else {
    ok(1,                             "queried result fetch (as map) unavailable as no service is running");
}
# Test 7.
if ($conn) {
    ok(defined $result{'LOCALPATH'},  "queried result fetch (as map) - LOCALPATH check");
} else {
    ok(1,                             "queried result fetch (as map) - LOCALPATH check unavailable as no service is running");
}
# Test 8.
if ($conn) {
    ok(defined $result{'SERVERMODEL'},"queried result fetch (as map) - SERVERMODEL check");
} else {
    ok(1,                             "queried result fetch (as map) - SERVERMODEL check unavailable as no service is running");
}
# Test 9.
if ($conn) {
    ok(defined $result{'UPTIME'},     "queried result fetch (as map) - UPTIME check");
} else {
    ok(1,                             "queried result fetch (as map) - UPTIME check unavailable as no service is running");
}

# Test 10
if ($conn) {
    $obj->query("INFO");
    my $line = $obj->fetch_status;
    ok(defined $line,                 "queried result fetch (status)");
} else {
    ok(1,                             "queried result fetch (status) unavailable as no service is running");
}

# Test 11
if ($conn) {
    $obj->query("INIT testDocumentForService");
    $obj->query("OPEN testDocumentForService");
    my @ape = split(/ /, $obj->fetch_status());
    my $sid = $ape[1];
    $obj->fetch_status();

    ok(defined $obj->shutdown($sid),  "shutdown");
} else {
    ok(1,                             "shutdown unavailable as no service is running");
}

# Test 12
if ($conn) {
    my %sessions = $obj->sessions();
    ok(%sessions,                     "sessions (non-extended)");
} else {
    ok(1,                             "sessions (non-extended) unavailable as no service is running");
}

# Test 13
if ($conn) {
    my @sids = split(/ /, $sessions{'SIDS'});
    ok(@sids,                         "sessions - has entries (fails if there are no sessions)");
} else {
    ok(1,                             "sessions - has entries unavailable as no service is running");
}

# Test 14
if ($conn) {
    my %sdata = $obj->get($sids[0]);
    ok(%sdata,                        "sessions - entry is hashmap");
} else {
    ok(1,                             "sessions - entry is hashmap unavailable as no service is running");
}

# Test 15
if ($conn) {
    ok(defined $sdata{'DOCUMENT'},    "sessions - entry has DOCUMENT key");
} else {
    ok(1,                             "sessions - entry has DOCUMENT key unavailable as no service is running");
}

# Test 16
if ($conn) {
    ok(!defined $sdata{'USERS'},      "sessions - entry doesn't have USERS key (not extended request)");
} else {
    ok(1,                             "sessions - entry doesn't have USERS key (not extended request) unavailable as no service is running");
}

# Test 17
if ($conn) {
    %sessions = $obj->sessions(1);
    ok(%sessions,                     "sessions (extended)");
} else {
    ok(1,                             "sessions (extended) unavailable as no service is running");
}

# Test 18
if ($conn) {
    @sids  = split(/ /, $sessions{'SIDS'});
    %sdata = $obj->get($sids[0]);
    ok(defined $sdata{'USERS'},       "sessions - entry has USERS key (extended request)");
} else {
    ok(1,                             "sessions - entry has USERS key (extended request) unavailable as no service is running");
}

# Test 19
if ($conn) {
    ok(defined $obj->fetch_info,      "fetch_info");
} else {
    ok(1,                             "fetch_info unavailable as no service is running");
}

# Test 20
if ($conn) {
    ok(defined $obj->disconnect,      "disconnect");
} else {
    ok(1,                             "disconnect unavailable as no service is running");
}
