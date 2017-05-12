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
# $Id: 01_Message.t,v 1.3 2003/05/04 02:59:10 peter Exp $
#

use Test::More tests => 14;
use Data::Dumper;


# 1
use_ok( 'Net::Whois::RIPE::Syncupdates::Message' );

# 2
ok( $m = Net::Whois::RIPE::Syncupdates::Message->new, 'new' );

# 3
ok( $m->setDBObject($o), 'setDBObject');

# 4
$changed_o = $m->getDBObject;

# for some reason we get extra leading whitespaces back
$changed_o =~ s/^\s*//gs;

ok( $changed_o eq $o, 'check changed object');

# 5
ok( $m->getOption(ORIGIN) eq '', 'default ORIGIN');

# 6
ok( $m->setOption(ORIGIN, $origin) eq $origin, 'change ORIGIN');

# 7
ok( $m->getOption(ORIGIN) eq $origin, 'check changed ORIGIN');

# 8
ok( $m->getOption(NEW) eq '', 'default NEW');

# 9
ok( $m->setOption(NEW, 1) eq 1, 'change NEW');

# 10
ok( $m->getOption(NEW) eq 1, 'check changed NEW');

TODO: {
    local $TODO = "decide what to do w/empty objects";

    # 11
    ok( $m->setDBObject('') eq '', 'setDBObject to empty value');

    # 12
    ok( $m->getDBObject eq '', 'check changed object');

    eval {
        $msg = $m->getMessage;
    };

    # 13
    ok( $@, 'getMessage throws exception for empty object');
}

$m->setDBObject($o);
$m->setOption(NEW);

# 14
ok( ! $@, 'no exception for non-empty object');


# Set up test values

BEGIN {

    $o = <<END_OBJ;
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

person:       Peter Banik
address:      Singel 258
address:      1016 AB Amsterdam
address:      The Netherlands
phone:        +31 20 535 4336
nic-hdl:      PB6-TEST
notify:       peter\@ripe.net
source:       TEST
remarks:      Added mnt-by
mnt-by:       PB7-TEST-MNT
remarks:      **************************
remarks:      Make love not war
remarks:      **************************
changed:      peter\@ripe.net 20020724
changed:      peter\@ripe.net 20020724
changed:      peter\@ripe.net 20020807
-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.2.1 (GNU/Linux)

iD8DBQE+et8V8boihhQ0vQYRAorRAJwPAeBoZc8P9Hpz7G8kEMZgHYGw5gCeNP+A
lEfwpQZZ0Tf1fksYu5Lsn5s=
=MLHB
-----END PGP SIGNATURE-----
END_OBJ

    $origin = 'eu.ripencc.peter';
}
