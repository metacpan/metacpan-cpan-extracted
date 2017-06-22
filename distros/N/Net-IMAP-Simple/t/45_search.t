use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests =
    (my $puts = 5)*1
    +1 # startup
    +2 # subject searches
    ;

our $imap;

sub run_tests {
    my $nm = $imap->select('testing')
        or die " failure selecting testing: " . $imap->errstr . "\n";

    ok( 0+$imap->search_unseen, 0 );

    for my $pnum (1 .. $puts) {
        $imap->put( testing => "Subject: test-$pnum\n\ntest-$pnum" );

        ok( 0+$imap->search_unseen, $pnum );
    }

    ok( 0+$imap->search_subject("test-"),  $puts );
    ok( 0+$imap->search_subject("test-3"), 1 );
}

do "./t/test_runner.pm";
