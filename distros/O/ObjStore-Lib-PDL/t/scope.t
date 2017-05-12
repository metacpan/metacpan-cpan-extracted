#!./perl -w

use strict;
use Test;
plan test => 3;

use ObjStore;
use ObjStore::Lib::PDL;

use vars qw($db $hv $pdl $chunk);
require "t/db.pm";

# PDL::Core::set_debugging(1);
#ObjStore::debug('bridge');

for (1..3) {
    begin 'update', sub {
	$pdl = ObjStore::Lib::PDL->new($db, { Dims => [3,3] });
	#$pdl->_debug(1);
	$chunk = $pdl->slice('1,1:2');
    };
    die if $@;

    eval { warn $pdl };
    ok $@, '/out of scope/';

    #PDL::dump($chunk);
    #eval { warn $chunk };
    #ok $@, '/outside/';
}

# should be reusing bridges!
#ok !ObjStore::Lib::PDL::_inuse_bridges();
#ok !ObjStore::_inuse_bridges();
