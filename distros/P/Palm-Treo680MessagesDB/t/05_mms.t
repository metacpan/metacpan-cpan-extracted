#!/usr/bin/perl -w
# $Id: 05_mms.t,v 1.2 2008/07/17 17:33:48 drhyde Exp $

use strict;
use vars qw($VAR1);

use Test::More tests => 6;

use Palm::PDB;
use Palm::Treo680MessagesDB;

my $pdb = Palm::PDB->new();
# $pdb->Load('t/regression/database.pdb');

local $/ = undef;

my @raw_records = map {
    open(RAW, "t/mms/$_") || die("Can't read t/mms/$_\n");
    my $r = <RAW>;
    close(RAW);
    $r;
} qw(ms-012.40.1232940.pdr ms-013.40.1232941.pdr ms-014.40.1232942.pdr);

my($complete_parsed, $incomplete_parsed) = map { do {
    open(my $file, "t/mms/$_.dd") || die("Can't read t/mms/$_.dd\n");
    eval <$file>;
} } qw(ms incomplete);

SKIP: { skip "MMS not yet working", 6;
ok(
    Palm::Treo680MessagesDB::_parseblob($raw_records[0])->{type} eq
    'unknown',
    "Read first bit of an MMS - message not yet complete"
);
is_deeply(
    $Palm::Treo680MessagesDB::multipart,
    {
        number    => '0901234567',
	name      => 'TaXX (M)',
	epoch     => 0,
	direction => 'outbound',
    },
    "Stored right info from first part"
);
    
ok(
    Palm::Treo680MessagesDB::_parseblob($raw_records[1])->{type} eq
    'unknown',
    "Read second bit of an MMS - message not yet complete"
);
is_deeply(
    $Palm::Treo680MessagesDB::multipart,
    {
        number    => '0901234567',
	name      => 'TaXX (M)',
	epoch     => 0,
	direction => 'outbound',
	attachments => [
	]
    },
    "Stored right info from second part"
);

is_deeply(
    Palm::Treo680MessagesDB::_parseblob($raw_records[2]),
    $complete_parsed,
    "Sample MMS from Michal Seliga correctly parsed"
);

is_deeply(
    $Palm::Treo680MessagesDB::multipart,
    {},
    "Multipart message cache cleared"
);
}
