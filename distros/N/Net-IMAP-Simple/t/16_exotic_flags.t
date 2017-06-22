use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 3;

our $imap;
    
sub run_tests {
    my $nm = $imap->select('testing')
        or die " failure selecting testing: " . $imap->errstr . "\n";

    $imap->put( testing => "Subject: test message" );
    $imap->add_flags(1 => qw(blarg fluurg carmel) );

    my @flags = $imap->msg_flags(1);
    ok( (grep {m/blarg/}  @flags), 1 );
    ok( (grep {m/fluurg/} @flags), 1 );
    ok( (grep {m/carmel/} @flags), 1 );
}

do "./t/test_runner.pm";
