our $tests;
our $imap;

use strict;
use IO::Socket::INET;
use Time::HiRes qw(time);
use Fcntl qw(:flock);
no warnings;

# 
# There used to be a little stand alone server than ran in this test suite.  It
# was totally unreliable and I tired of trying to maintain it.  You must now
# test against your own server if you wish to test.  I highly recommend
# skipping the tests.  If you choose to report errors, please also explain why
# they failed.
#
### these tests are all tuned for gmail, used to test best on dovecot ###
# 
# For example, the last failures from CPAN Testers seemed to be segmentation
# faults in SSL that I couldn't reproduce at my house or at work.  Not really a
# perl problem and not really something I can fix.
#
# On the other hand, it could be a simple network or process management error.
# How can I tell from here?  TAP wasn't really set up to deal with process
# management the way I was doing it.  I gave up.
#
# If you want to test, set these environment variables and run the tests.
# These settings are intentionally un-obvious.  If you want to run automated
# tests please help debug the failures.  Automated test results against unknown
# environments help absolutely nobody at all.  Your IMAP server will differ
# from mine, so some of the tests will fail and I won't have any ability to
# figure out why without your /tmp/ logs and/or some help.  With most modules
# cpan testers is the best thing in the entire world.  With IMAP, not so much.
#
#     ** THIS WILL DESTROY ANY FOLDERS YOU HAVE NAMED
#     **      TESTING, TESTING2 OR TESTING3
#
#     export NIS_TEST_HOST=someserver.org
#     export NIS_TEST_USER=someguyname
#     export NIS_TEST_PASS=blarg
#
#     ** THIS WILL DESTROY ANY FOLDERS YOU HAVE NAMED
#     **      TESTING, TESTING2 OR TESTING3
#  
# HOST will get connections on 143 and 993, specifying a port is not possible
# at this time.
#
#

open my $lock, ">", "t/test_runner.pm.lock" or die "couldn't open lockfile: $!";
flock $lock, LOCK_EX or die "couldn't lock lockfile: $!";

unless( exists $ENV{NIS_TEST_HOST} and exists $ENV{NIS_TEST_USER} and exists $ENV{NIS_TEST_PASS} ) {
    ok($_) for 1 .. $tests;  # just skip everything
    my $line = "[not actually running any tests -- see t/test_runner.pm]";
    my $len = length $line; $len ++;
    print STDERR "\e7\e[5000C\e[${len}D$line\e8";
    exit 0;
}

open INFC, ">/tmp/client-run-" . time . ".log";
# we don't care very much if the above command fails

our $CALLBACK_TEST;

my @c = $CALLBACK_TEST ? (readline_callback => $CALLBACK_TEST) :();

our $USE_SIMPLEX;

my $class = $USE_SIMPLEX ? "Net::IMAP::SimpleX" : "Net::IMAP::Simple";

$imap = $class->new($ENV{NIS_TEST_HOST}, debug=>\*INFC, @c, use_ssl=>1) or die "\nconnect failed: $Net::IMAP::Simple::errstr\n";

$imap->login(@ENV{qw(NIS_TEST_USER NIS_TEST_PASS)});

if( __PACKAGE__->can('run_tests') ) {
    for my $mb (qw(testing testing1 testing2 testing3)) {
        $imap->create_mailbox($mb);
        my $nm = $imap->select($mb);
        if( $nm > 0 ) {
            $imap->delete("1:$nm");
            $imap->expunge_mailbox;
        }
    }

    eval {
        run_tests();

    1} or warn "\nfail: $@\n";

    for my $mb (qw(test anotherthing blarg testing testing1 testing2 testing3)) {
        my $nm = $imap->select($mb);
        if( defined $nm ) {
            if ( $nm > 0 ) {
                $imap->delete("1:$nm");
                $imap->expunge_mailbox;
            }
            # must get off the selected mailbox before delete
            # or imap expects us to quit and will die in weird ways
            $imap->select("INBOX");
            $imap->delete_mailbox($mb);
        }
    }

} else {
    warn "weird, no tests";
}

777;
