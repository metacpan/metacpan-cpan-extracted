use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 4;

our $imap;

sub run_tests {
    my $nm = $imap->select('testing')
        or die " failure selecting testing: " . $imap->errstr . "\n";

    ok( $imap->select("testing")+0, 0 );

    $imap->put( testing => "Subject: test-$_\n\ntest-$_", '\Seen' ) for 1 .. 10;
    $imap->delete( "3:4,6" ) or warn $imap->errstr;
    my @e = $imap->expunge_mailbox;
    ok( not $imap->waserr );
    ok( "@e", qr(6 4 3|3 3 4) ); # (rational dovecot following imap sec | gmail doing its own thing)

    ok( $imap->last, 7 );
}   

do "./t/test_runner.pm";

