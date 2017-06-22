use strict;
use warnings;

use Test;

use Net::IMAP::SimpleX;

plan tests => our $tests = 4 + (3+2);

our $imap;
our $USE_SIMPLEX = 1;

sub run_tests {
    my $nm = $imap->select('testing')
        or die " failure selecting testing: " . $imap->errstr . "\n";

    $imap->put( testing => "Subject: test" );

    my $bs = $imap->body_summary(1);
    ok( not $bs->has_parts() );
    ok( not $bs->type() );
    ok( not $bs->parts() );
    ok( $bs->body()->content_type(), qr"text/plain"i );

    $imap->put( testing => <<TEST2 );
From jettero\@cpan.org Wed Jun 30 11:34:39 2010
Subject: something
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="0-1563833763-1277912078=:86501"

--0-1563833763-1277912078=:86501
Content-Type: text/plain; charset=fake-charset-1

Text Content.

--0-1563833763-1277912078=:86501
Content-Type: text/html; charset=fake-charset-2

<p>HTML Content</p>

--0-1563833763-1277912078=:86501--

TEST2

    $bs = $imap->body_summary(2);
    ok( $bs->has_parts() );
    ok( $bs->type(), qr"alternative"i );
    ok( scalar (my @parts = $bs->parts()), 2 );

    ok( $parts[0]->content_type(), qr"text/plain"i );
    ok( $parts[1]->content_type(), qr"text/html"i );

    # gmail eats the fake charsets
    # ok( $parts[0]->charset(), "fake-charset-1" );
    # ok( $parts[1]->charset(), "fake-charset-2" );
}

do "./t/test_runner.pm";
