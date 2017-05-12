# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Passwd::DB qw(getpwnam modpwinfo setpwinfo rmpwnam mgetpwnam init_db);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "Testing in Object context\n";

$db = Passwd::DB->new("./TestDB-Object",1);
print "ok 2\n";

@minfo = ('bob', '*LK*', '10000', '10000', 'bob gecos', '/bob/home', '/bob/shell');

$err = $db->modpwinfo(@minfo);
if ($err == 2) {
    print "ok 3\n";
} else {
    print "not ok 3, modpwinfo didn't fail with user doesn't exist\n";
}

$err = $db->setpwinfo(@minfo);
if ($err == 0) {
    print "ok 4, created $minfo[0]\n";
} else {
    print "not ok 4, setpwinfo failed\n";
    exit;
}

undef @info;
@info = $db->getpwnam('bob');
if (@info) {
    print "ok 5, @info\n";
} else {
    print "not ok 5, getpwnam failed\n";
}

undef @minfo;
@minfo = $db->mgetpwnam('bob');
if (@minfo) {
    print "ok 6, @minfo\n";
} else {
    print "not ok 5, mgetpwnam failed\n";
}

$err = $db->rmpwnam('bob');
if ($err == 0) {
    print "ok 7, deleted bob\n";
} else {
    print "not ok 7, rmpwnam failed\n";
}

print "Testing in Non-Object Context\n";

Passwd::DB->init_db("./TestDB-NonObj",1);
print "ok 8\n";

@minfo = ('bob', '*LK*', '10000', '10000', 'bob gecos', '/bob/home', '/bob/shell');

$err = modpwinfo(@minfo);
if ($err == 2) {
    print "ok 9\n";
} else {
    print "not ok 9, modpwinfo didn't fail with user doesn't exist\n";
}

$err = setpwinfo(@minfo);
if ($err == 0) {
    print "ok 10, created $minfo[0]\n";
} else {
    print "not ok 10, setpwinfo failed\n";
    exit;
}

undef @info;
@info = getpwnam('bob');
if (@info) {
    print "ok 11, @info\n";
} else {
    print "not ok 11, getpwnam failed\n";
}

undef @minfo;
@minfo = mgetpwnam('bob');
if (@minfo) {
    print "ok 12, @minfo\n";
} else {
    print "not ok 12, mgetpwnam failed\n";
}

$err = rmpwnam('bob');
if ($err == 0) {
    print "ok 13, deleted bob\n";
} else {
    print "not ok 13, rmpwnam failed\n";
}

