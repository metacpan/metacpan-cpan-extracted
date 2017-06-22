use strict;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 2;

our $imap;

sub run_tests {
    $imap->create_mailbox("anotherthingy");

    my @e = $imap->mailboxes;
    my @E = qw(testing anotherthingy);

    for my $__e (@E) {
        ok(1) if grep { $_ eq $__e } @e; # would use ~~ but would rule out 5.8 boxes
    }
}   

do "./t/test_runner.pm";
