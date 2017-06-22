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

    my @res;
    ok( $res[0] = $imap->copy( "3:5,9", 'testing2' ) );
    ok( $res[1] = $imap->copy( "1,7",   'testing2' ) );
    ok( $res[2] = $imap->select("testing2"), 6 );
}   

do "./t/test_runner.pm";
