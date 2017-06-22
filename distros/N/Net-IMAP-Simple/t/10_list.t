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

    my $msg = "Subject: test!\n\ntest!";
    $imap->put( blarg => $msg );
    $imap->select('blarg');

    $h = $imap->list();
    ok( ref $h, "HASH" );
    ok( int(keys %$h), 1 );
    my ($v) = values %$h;

    my $bytes = $ENV{NIS_TEST_HOST} =~ m/gmail/ ? length($msg) : length($msg)+2;
    ok( $v, $bytes )
}

do "./t/test_runner.pm";
