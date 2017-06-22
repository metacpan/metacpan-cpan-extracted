use strict;
use warnings;

use Test;
use Net::IMAP::Simple;

plan tests => our $tests = 2;

my $append_ok = 0;
my $get_ok    = 0;

sub callback_test {
    my ($line) = @_;

    # e.g.: 5 OK [APPENDUID 1283347568 1002] APPEND COMPLETED
    $append_ok ++ if $line =~ m/\d+\s+OK.+?APPENDUID.+?APPEND.+?COMPLETED/i;
    $get_ok    ++ if $line =~ m/test-\d+!/;
}

our $CALLBACK_TEST = \&callback_test;
our $imap;

sub run_tests {

    my $nm = $imap->select("testing");

    $imap->put( testing => "Subject: test!\n\ntest-$_!" ) for 1 .. 5;
    $imap->get( $_ ) for 1 .. 5;

    ok( $append_ok, 5 );
    ok( $get_ok,    5 );
}

do "./t/test_runner.pm";
