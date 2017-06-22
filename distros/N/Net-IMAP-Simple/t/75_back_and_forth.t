use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => (our $tests = 10 + 3);

our $imap;

sub run_tests {
    my $nm = $imap->select('testing')
        or die " failure selecting testing: " . $imap->errstr . "\n";

    $imap->create_mailbox('test');

    ok( $imap->select("testing")+0, 0 );
    $imap->put( testing => "Subject: test-$_\n\ntest-$_" . "\n" . (" xxxxxx " x 2_000), '\Seen' ) for 1 .. $tests;
    ok( $imap->select("testing")+0, $tests );

    for my $i ( 1 .. ($tests-3) ) {
        my $errors = 0;
        my $msg = $imap->get($i)   or do { $errors ++; warn " " . $imap->errstr };
        $imap->put( test => $msg ) or do { $errors ++; warn " " . $imap->errstr };
        $imap->delete( $i )        or do { $errors ++; warn " " . $imap->errstr };

        ok($errors, 0);
    }

    # hey, look at that... dovecot produces this error on its own
    # [...blib/lib/Net/IMAP/Simple.pm line 1181 in sub _send_cmd] 56 FETCH 913 RFC822\r\n
    # [...blib/lib/Net/IMAP/Simple.pm line 725 in sub _process_cmd] 56 BAD Error in IMAP command FETCH: Invalid messageset\r\n
    # [...blib/lib/Net/IMAP/Simple.pm line 1201 in sub _cmd_ok] 56 BAD Error in IMAP command FETCH: Invalid messageset\r\n


    $imap->get($tests + 9_00); # finishing move
    ok( $imap->errstr, qr(Invalid messageset|message not found)i );
}   

do "./t/test_runner.pm";
