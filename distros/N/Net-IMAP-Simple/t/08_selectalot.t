use strict;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 3;

our $imap;

sub run_tests {
    $imap->select("testing") or warn " \e[1;33m" . $imap->errstr . "\e[m\n";
    ok( $imap->current_box, "testing" );

    $imap->select("reallynowaythissuckerexistsIhope");
    ok( $imap->current_box, "testing" );

    $imap->create_mailbox("anotherthingy");

    $imap->select("anotherthingy") or warn " \e[1;33m" . $imap->errstr . "\e[m\n";
    ok( $imap->current_box, "anotherthingy" );
}

do "./t/test_runner.pm";
