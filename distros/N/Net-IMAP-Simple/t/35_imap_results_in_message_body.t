use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 1;

my $special_message = <<"HERE";
From: me
To: you
Subject: supz!

1 OK FETCH COMPLETED\r
2 OK FETCH COMPLETED\r
3 OK FETCH COMPLETED\r
4 OK FETCH COMPLETED\r
5 OK FETCH COMPLETED\r

Hi, this is a message, do you like it?

HERE

our $imap;

sub run_tests {
    my $nm = $imap->select('testing')
        or die " failure selecting testing: " . $imap->errstr . "\n";

    $imap->put( testing => $special_message );

    my $return = $imap->get(1);

    $special_message =~ s/\x0d?\x0a/\x07/g;
    $return =~ s/\x0d?\x0a/\x07/g;

    ok( $return, $special_message );
}   

do "./t/test_runner.pm";
