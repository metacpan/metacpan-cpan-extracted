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
# $Id: sup_client.pl,v 1.3 2003/04/09 20:05:02 peter Exp $
#
use strict;

use Data::Dumper;
use Net::Whois::RIPE::Syncupdates;
use Net::Whois::RIPE::Syncupdates::Message;

my $o = <<END_OBJ;
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
nic-hdl:      NWRS3-TEST
notify:       peter\@ripe.net
changed:      peter\@ripe.net 20030409
source:       TEST
END_OBJ

print "OBJECT BEING SUBMITTED:\n", $o, "\n\n";

my $sup = Net::Whois::RIPE::Syncupdates->new(
    url => 'http://www.ripe.net/syncupdates-test/',
);

$sup->message->setOption(ORIGIN, 'Net::Whois::RIPE::Syncupdates TEST');

$sup->message->setDBObject($o);

my $r = $sup->execute;

print "RESULT CODE: ", $r->getCode(), "\n";

print "FULL MESSAGE: ", $r->asString(), "\n";


