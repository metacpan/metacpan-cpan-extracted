use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 6;

our $imap;

sub run_tests {
    my $nm = $imap->select('testing')
        or die " failure selecting testing: " . $imap->errstr . "\n";

    if( $nm ) {
        $imap->delete("1:$nm");
        $imap->expunge_mailbox;
    }

    ok( $imap->select("testing")+0, 0 );

    $imap->put( testing => "Subject: test-$_\n\ntest-$_", '\Seen' ) for 1 .. 10;

    my ($unseen, $recent, $total) = $imap->status;
    ok( "unseen $unseen", "unseen 0" );
    ok( "total  $total",  "total  10" );

    $imap->unsee($_) for 5,7;
    ok( "funseen " . $imap->unseen, 'funseen 2' );

    ($unseen, $recent, $total) = $imap->status;
    ok( "unseen $unseen", "unseen 2" );
    ok( "total  $total",  "total  10" );
}

do "./t/test_runner.pm";
