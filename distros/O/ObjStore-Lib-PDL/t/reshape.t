# -*-perl-*- math
use strict;
use Test; plan test => 4, todo => [3];

use ObjStore;
use ObjStore::Lib::PDL;

# ObjStore::debug('bridge','txn');
# PDL::Core::set_debugging(100);

use vars qw($db);
require "t/db.pm";

begin 'update', sub {
    my $p = ObjStore::Lib::PDL->new($db, { Dims => [3,3] });
    #$p->_debug(1);
    $p->setdims([4,4]);
    ok join('',$p->dims), '44';

    # try switching types
    my $x = $p->slice(':,1')->clump(2);
    $x .= PDL->sequence(4) + 254;

    my $byte = PDL::byte()->[0];
    $p->set_datatype($byte);

#    warn ObjStore::Lib::PDL::_inuse_bridges(1);

    ok $p->get_datatype, $byte;
    ok $p->at(0,1), 254;
};
die if $@;

ok !ObjStore::_inuse_bridges();
