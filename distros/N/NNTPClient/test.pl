# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {print "1..37\n";}
END {print "not ok 1\n" unless $loaded;}
use News::NNTPClient;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print <<EOF;

    These tests are as much a test of your news server as they are a
    test of News::NNTPClient.  Not all of these tests will pass.

    The following tests rely on the existence of an available news
    server.  If the environment variable NNTPSERVER is not set, then
    "news" will be used.  If you don't have access to a news server,
    ok(), okprint(), code(), and postok() will fail.  postok() will
    also fail if you don't have permission to post.

EOF

$i = 2;

$c = new News::NNTPClient;

$c->gmt(1);
$c->fourdigityear(1);

for $f (qw(version debug eol gmt fourdigityear message code
	   ok okprint postok mode_reader list help slave)) {
  print "not " unless $c->$f();
  print "ok ", $i++, " ($f)\n";
}

print <<EOF;

    In addition to needing access to a news server, the following
    tests also rely on the existence and permission to post to the
    news group "test".

EOF

$TESTGROUP = "test";

print "not " unless $c->post(split(/\n/,<<EOF));
Newsgroups: $TESTGROUP
From: tester\@localhost.
Subject: test

Body Of Test.
EOF

print "ok ", $i++, " (post)\n";

print "not " unless ($first, $last) = $c->group($TESTGROUP);
print "ok ", $i++, " (group)\n";

for $f (qw(article body head last next stat)) {
  print "not " unless $msgid = $c->$f($last);
  print "ok ", $i++, " ($f)\n";
}

# My server does not understand four digit years.
$c->fourdigityear(0);

for $f (qw(newgroups newnews)) {
  print "not " unless $c->$f(time());
  print "ok ", $i++, " ($f)\n";
}

# I can't test these two, and I doubt many people can.
# ihave authinfo


for $f (qw(date listgroup)) {
  print "not " unless $c->$f();
  print "ok ", $i++, " ($f)\n";
}

print <<EOF;

    The following are all "extra" commands that may or may not be
    implemented on your server.  Those that are not implemented should
    show an NNTPERROR: 500

EOF

# xpath xgtitle xhdr xpat xover xmotd xthread xindex xsearch

print "not " unless $c->xpath($msgid);
print "ok ", $i++, " (xpath $msgid)\n";

for $f (qw(xgtitle xhdr xpat xover xmotd xthread xindex xsearch)) {
  print "not " unless $c->$f();
  print "ok ", $i++, " ($f)\n";
}

print <<EOF;

    Remember, just because some tests failed doesn't mean that there
    is anything wrong with News::NNTPClient.  These tests also depend
    on the proper operation and implementation of your news server.
    For example, the XPATH command on my server does not seem to work
    anymore.

EOF

# This should be last
print "not " unless $c->quit();
print "ok ", $i++, " (quit)\n";
