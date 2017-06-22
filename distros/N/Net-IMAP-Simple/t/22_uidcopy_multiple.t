use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 5;

our $imap;

sub run_tests {
    my $nm = $imap->select('testing')
        or die " failure selecting testing: " . $imap->errstr . "\n";

    ok( $imap->select("testing")+0, 0 );

    $imap->put( testing => "Subject: test-$_\n\ntest-$_", '\Seen' ) for 1 .. 10;
    ok( $imap->select("testing")+0, 10 );

    $imap->create_mailbox("testing2");

    my @_uid359 = $imap->uid("3:5,9");
    my @_uid17  = $imap->uid("1,7");

    ok($imap->uidcopy( join(",",@_uid359), 'testing2' ) );
    ok($imap->uidcopy( join(",",@_uid17),  'testing2' ) );
    ok($imap->select("testing2"), 6 );
}   

do "./t/test_runner.pm";
