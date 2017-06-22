
use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 3;

our $imap;

sub run_tests {
    $imap->create_mailbox("blarg");
    my $n = $imap->select("blarg");
    $imap->delete("1:$n");
    $imap->expunge_mailbox;

    $imap->select("blarg");
    $imap->put( blarg => "Subject: test$_\n\ntest$_" ) for 1..2;

    my @r = $imap->top;
    my @a = "@r" =~ m/(test\d+)/g;

    ok( "@a", "test1 test2" );

    @r = $imap->top(1);
    @a = "@r" =~ m/(test\d+)/g;

    ok( "@a", "test1" );

    @r = $imap->top(2);
    @a = "@r" =~ m/(test\d+)/g;

    ok( "@a", "test2" );
}

do "./t/test_runner.pm";
