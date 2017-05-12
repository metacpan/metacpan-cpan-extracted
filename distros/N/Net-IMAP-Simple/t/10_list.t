BEGIN { unless( $ENV{I_PROMISE_TO_TEST_SINGLE_THREADED} ) { print "1..1\nok 1\n"; exit 0; } }

use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 5;

our $imap;

sub run_tests {
    $imap->create_mailbox("blarg");
    my $n = $imap->select("blarg");
    $imap->delete("1:$n");
    $imap->expunge_mailbox;

    $imap->select("blarg");

    my $h = $imap->list();
    ok( ref $h, "HASH" );
    ok( int(keys %$h), 0 );

    $imap->put( blarg => "Subject: test!\n\ntest!" );
    $imap->select('blarg');

    $h = $imap->list();
    ok( ref $h, "HASH" );
    ok( int(keys %$h), 1 );
    my ($v) = values %$h;
    ok( $v == 21 || $v == 25 ); # dovecot puts another \r\n on the end (or something like that) and is 25 instead of the expected 21 bytes
}

do "t/test_runner.pm";
