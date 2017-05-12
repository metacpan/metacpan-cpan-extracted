#!/usr/bin/perl
#
# $HeadURL: https://svn.oucs.ox.ac.uk/networks/src/debian/packages/libr/libmodule-multiconf-perl/trunk/t/60-mandatory.t $
# $LastChangedRevision: 1313 $
# $LastChangedDate: 2007-07-07 21:10:33 +0100 (Sat, 07 Jul 2007) $
# $LastChangedBy: oliver $
#

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;

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

package ConfTest;
ConfTest->Validate->{rpc_serialized}->{new_test} = {type => SCALAR};
package main;

eval { $c = $c->parse($c) };
like( $@, qr/Mandatory parameter 'new_test' missing/, "Mandatory parameter" );

eval { $c = $c->parse({rpc_serialized => {new_test => [1,2,3]}}) };
like( $@, qr/The 'new_test' parameter.+was an 'arrayref', which is not one of the allowed types: scalar/, "Mandatory parameter wrong type" );

eval { $c = $c->parse({rpc_serialized => {new_test => 1}}) };
ok( ! $@, "Loaded with required param: $@" );

