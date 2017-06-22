use strict;
use warnings;

use Test;

BEGIN {
    if( not -f "test_simplex" ) {
        plan tests => 1;
        print "# skipping all tests, not installing SimpleX\n";
        skip(1,1,1);
        exit 0;
    }
}

use Net::IMAP::SimpleX;

plan tests => our $tests = (
    1   # the sample test
    + 1 # keys=5
    + 2 # UIDs
    + 2 # HEADER FIELDS
    + 2 # UID HEADER FIELDS
);

my $sample = q/* 1 FETCH (FLAGS (\Recent) INTERNALDATE "23-Jul-2010 22:21:37 -0400" RFC822.SIZE 402/
. q/ ENVELOPE (NIL "something" NIL NIL NIL NIL NIL NIL NIL NIL) BODYSTRUCTURE (("text" "plain" ("charset" "fake-charset-1")/
. qq/ NIL NIL "7BIT" 15 2)("text" "html" ("charset" "fake-charset-2") NIL NIL "7BIT" 21 2) "alternative"))\x0d\x0a/;

our $imap;
our $USE_SIMPLEX = 1;

sub run_tests {

    my $parser = $imap->{parser}{fetch};
    my $bool   = $parser->fetch_item($sample) ? 1:0;

    ok( $bool ) or warn " couldn't parse: $sample";

    my $nm = $imap->select('testing')
        or die " failure selecting testing: " . $imap->errstr . "\n";

    $imap->put(testing=>$_) for get_messages();

    my %parts = eval { %{ $imap->fetch(1=>'FULL')->{1} } };
    ok( int( keys %parts ), 5 ) or warn do {my @a = keys %parts; "parts(@a)"};

    my $res = $imap->fetch('1:*', "UID BODY[HEADER.FIELDS (DATE FROM SUBJECT)]");

    my $uid1 = $res->{1}{UID};
    my $uid2 = $res->{2}{UID};

    ok( $uid1 > 0 and $uid2 > 0 );
    ok( $uid1      != $uid2 );

    ok( $res->{1}{'BODY[HEADER.FIELDS (DATE FROM SUBJECT)]'} =~ m/1:09.*Paul Miller.*test message/s );
    ok( $res->{2}{'BODY[HEADER.FIELDS (DATE FROM SUBJECT)]'} =~ m/4:12.*Paul Miller.*test2/s );

    $res = $imap->uidfetch("$uid1,$uid2", "UID BODY[HEADER.FIELDS (DATE FROM SUBJECT)]");

    ok( $res->{1}{'BODY[HEADER.FIELDS (DATE FROM SUBJECT)]'} =~ m/1:09.*Paul Miller.*test message/s );
    ok( $res->{2}{'BODY[HEADER.FIELDS (DATE FROM SUBJECT)]'} =~ m/4:12.*Paul Miller.*test2/s );
}

do "./t/test_runner.pm";

sub get_messages {
    my @messages = (<<TEST1, <<TEST2);
From jettero\@cpan.org Sat Jul 24 10:01:11 2010
Return-Path: <jettero\@cpan.org>
Received: from voltar.org (x-x-x-x.lightspeed.klmzmi.sbcglobal.net [0.0.0.0])
        by mx.google.com with ESMTPS id n20sm1380887ibe.17.2010.07.24.07.01.10
        (version=TLSv1/SSLv3 cipher=RC4-MD5);
        Sat, 24 Jul 2010 07:01:11 -0700 (PDT)
Sender: Paul Miller <jettero\@cpan.org>
Date: Sat, 24 Jul 2010 10:01:09 -0400
From: Paul Miller <jettero\@cpan.org>
To: Paul Miller <jettero\@cpan.org>
Subject: test message
Message-ID: <20100724140108.GA19962\@corky>
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline
User-Agent: Mutt/1.5.20 (2009-06-14)
Status: RO
Content-Length: 158
Lines: 7


this is the test part


--
If riding in an airplane is flying, then riding in a boat is swimming.
116 jumps, 48.6 minutes of freefall, 92.9 freefall miles.

TEST1
From jettero\@cpan.org Sat Jul 24 10:04:15 2010
Return-Path: <jettero\@cpan.org>
Received: from cpan.org (x-x-x-x.lightspeed.klmzmi.sbcglobal.net [0.0.0.0])
        by mx.google.com with ESMTPS id e8sm1384214ibb.14.2010.07.24.07.04.14
        (version=TLSv1/SSLv3 cipher=RC4-MD5);
        Sat, 24 Jul 2010 07:04:14 -0700 (PDT)
Sender: Paul Miller <jettero\@cpan.org>
Date: Sat, 24 Jul 2010 10:04:12 -0400
From: Paul Miller <jettero\@cpan.org>
To: Paul Miller <jettero\@cpan.org>
Subject: test2
Message-ID: <20100724140412.GA20361\@corky>
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline
User-Agent: Mutt/1.5.20 (2009-06-14)


test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2 test2
test2 test2 test2 test2 test2

--
If riding in an airplane is flying, then riding in a boat is swimming.
116 jumps, 48.6 minutes of freefall, 92.9 freefall miles.
TEST2
}
