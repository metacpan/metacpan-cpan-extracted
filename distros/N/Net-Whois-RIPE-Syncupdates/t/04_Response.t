# Copyright (c) 1993 - 2002 RIPE NCC
#
# All Rights Reserved
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose and without fee is hereby granted,
# provided that the above copyright notice appear in all copies and that
# both that copyright notice and this permission notice appear in
# supporting documentation, and that the name of the author not be
# used in advertising or publicity pertaining to distribution of the
# software without specific, written prior permission.
#
# THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
# ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS; IN NO EVENT SHALL
# AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
# DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
# AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#
# $Id: 04_Response.t,v 1.2 2003/05/04 03:32:11 peter Exp $
#

#
# The test cases in this file actually talk to the backend, ie need
# an accessible Whois database and the syncupdates CGI installed.
#

use Test::More;

# 1
use_ok( 'Net::Whois::RIPE::Syncupdates' );

# 2
ok( $sup = Net::Whois::RIPE::Syncupdates->new( url => $TEST_URL ), 'new' );

# 5
ok( $sup->message->setOption(ORIGIN, $ORIGIN) eq $ORIGIN, 'set ORIGIN');

# 6
ok( $sup->message->getOption(ORIGIN) eq $ORIGIN, 'check ORIGIN');

# 7
ok( $sup->message->setDBObject($OBJECT) eq "\n\n$OBJECT", 'set object');

# Functional tests -- these need actual backend connection
# We should ask a question here whether to go further or just stop.

eval {
    $r = $sup->execute;
};

# 8
ok( ! $@, 'no exception from execute');

# 9
ok( ref($r) eq 'Net::Whois::RIPE::Syncupdates::Response', 'execute() returns a Response object' );

ok( $r->getCode eq '200', 'HTTP status = 200');

#diag($r->asString);

# Set up test values

BEGIN {

    $OBJECT = <<END_OBJ;
person:       Net Whois RIPE Syncupdates
remarks:      ==========================
remarks:
remarks:      This is an object for testing
remarks:      the Net::Whois::RIPE::Syncupdates
remarks:      library.
remarks:
remarks:      http://www.ripe.net/
remarks:
remarks:      ==========================
address:      Singel 258
address:      1016 AB Amsterdam
address:      The Netherlands
phone:        +31 20 5354444
fax-no:       +31 20 5354445
e-mail:       peter\@ripe.net
notify:       peter\@ripe.net
changed:      peter\@ripe.net 20030409
nic-hdl:      NWRS3-TEST
source:       TEST
END_OBJ

    $ORIGIN = 'Net::Whois::RIPE::Syncupdates test suite';

    $TEST_URL = $ENV{TEST_URL};

    # First, check whether or not we have a backend URL to talk to within
    # this test.  If there is no available backend, we skip this test suite
    # entirely.

    if($TEST_URL){
        plan 'no_plan';
    } else {
        plan skip_all => "This test suite needs a backend URL, which was not specified." ;
    }
    diag("Using syncupdates backend URL: $TEST_URL");

}
