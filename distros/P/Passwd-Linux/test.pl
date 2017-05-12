# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; if ($< == 0) { print "1..5\n"; } else {print "1..2\n";} }
END {print "not ok 1\n" unless $loaded;}
use Passwd::Linux qw(modpwinfo rmpwnam setpwinfo mgetpwnam);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

undef @info;
if ($< != 0) { # if we aren't root just do a quick test of fetching
    @info = mgetpwnam("root");
    if (@info) {
        print "ok 2\n";
    } else {
        print "not ok 2\n";
    }
    exit;
}

# test of NO_CREATE
@info = mgetpwnam("tBoBt"); # a very unlikely candidate
if (defined($info[0])) {
    print "please modify test.pl tBoBt username to one that doesn't exist on your system\n";
    exit;
}
# doesn't exist, on with the testing

@info = ("tBoBt", "*LK*", 10000, 10000, "Test Bob", "/tmp", "/bin/noshell");
#print "info = @info\n";

$err = modpwinfo(@info);
if ($err != 2) {
    print "not ok 2\n";
    exit;
} else {
    print "ok 2\n";
}

$err = setpwinfo(@info);
#print "err = [$err]\n";
if ($err != 0) {
    print "not ok 3 [err = $err, $!]\n";
    exit;
} else {
    print "ok 3 $info[0] was created, you might have to manually delete it.\n";
}

$info[4] = "Bob Test";
push @info, 0, 0, 99999, 7, 1, 2;

$err = modpwinfo(@info);
if ($err != 0) {
    print "not ok 4 [err = $err, $!]\n";
    exit;
}

@change = mgetpwnam($info[0]);
if (($change[4] ne "Bob Test") || ($change[12] != 2)) {
    print "not ok 4, entry was changed to @change\n";
} else {
    print "ok 4\n";
}

$err = rmpwnam($info[0]);
if ($err != 0) {
    print "not ok 5 [you will need to delete user entry for $info[0]\n";
    print "[err = $err, $!]\n";
}

@info = getpwnam($info[0]);
if (defined($info[0])) {
    print "not ok 5, $info[0] still exists rmpwnam failed (you'll have to delete)\n";
} else {
    print "ok 5, successfully removed $info[0]\n";
}
