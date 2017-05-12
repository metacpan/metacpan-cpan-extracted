# -*-perl-*-
use strict;
use Test;
BEGIN { plan test => 19 }

eval q[ require Devel::Carp ];
use ObjStore;
use ObjStore::Lib::PDL;

if (0) {
    no strict 'refs';
    for (@PDL::Core::PP) {
	&{"$_\::set_boundscheck"}(1)
    }
}

kill 'INT',$$ if $ENV{HITME};

use vars qw($db);
require "t/db.pm";
#ObjStore::debug('bridge');

begin 'update', sub {
    my $top = $db->root('hv', sub { {} });
#    my $top = ObjStore::HV->new('transient');

    for my $ty (qw(byte short ushort long float double)) {
	my $pdl = PDL->sequence(3, 3)->$ty();
	skip !exists $top->{$ty}, sub {
	    (($top->{$ty} == $pdl)->min)
	};
	$top->{$ty} = $pdl;
	ok (($top->{$ty} == $pdl)->min);
	ok $top->{$ty}->get_datatype, $pdl->get_datatype;
    }
};
die if $@;

ok !ObjStore::_inuse_bridges();
