#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/networks/src/debian/packages/libr/libmodule-multiconf-perl/trunk/t/40-validate.t $
# $LastChangedRevision: 1313 $
# $LastChangedDate: 2007-07-07 21:10:33 +0100 (Sat, 07 Jul 2007) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;

package ConfTest;
use Module::MultiConf;
ConfTest->Validate({
    log_dispatch_syslog => {
        name      => { type => SCALAR, default => 'rpc-serialized' },
        min_level => { default => 'debug' },
        facility  => { default => 'local0' },
        callbacks => { default => sub { return "$_[1]\n" } },
    },
    rpc_serialized => {
        debug => { default => 0 },
        trace => { default => 0 },
    },
});

ConfTest->Force({
    data_serializer => {
        portable => 1,
    },
});

package main;

my $c = ConfTest->new;
ok( ! $@, "Tried to load itself: $@" );
isa_ok( $c, 'ConfTest' );

can_ok( $c, 'rpc_serialized' );
is( $c->rpc_serialized->{debug}, 0, "Validate defaults" );
