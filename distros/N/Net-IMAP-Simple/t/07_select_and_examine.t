use strict;
no warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 16;

our $imap;
my $nm;

sub run_tests {
    my $nm = $imap->select("testing") or die "imap error: " . $imap->errstr;
    $nm = $imap->select("testing");

    $imap->put( testing => "Subject: test!\n\ntest!" ) or die "problem putting message: " . $imap->errstr;

    my @c = (
        [ scalar $imap->select("fake"),    $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
        [ scalar $imap->select("testing"), $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
        [ scalar $imap->select("fake"),    $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
        [ scalar $imap->select("testing"), $imap->current_box, $imap->unseen, $imap->last, $imap->recent ],
    );

    ok( $c[$_][1], "testing" ) for 0 .. $#c;

    ok( $c[0][0], undef );
    ok( $c[1][0], $nm+1 );
    ok( $c[2][0], undef );
    ok( $c[3][0], $nm+1 );
    ok( "@{ $c[$_] }[2,3,4]", "1 1 0" ) for 0 .. $#c;

    ## Test EXMAINE

    ok( $imap->examine('testing') );
    # ok( not $imap->put( testing => "Subject: test!\n\ntest!" ) );
    # ok( $imap->errstr, qr/read.*only/ );
    # this worked in Net::IMAP::Server -- dovecot apparently lets you append after examine... heh

    ok( $nm = $imap->select('testing') );
    ok( $imap->put( testing => "Subject: test!\n\ntest!" ), 1 )
        or die " error putting test message: " . $imap->errstr . "\n";
    ok( $imap->select('testing'), 2 );
}

do "./t/test_runner.pm" == 777 or die "test-runner-failed: $@$!";
