#!/usr/bin/perl
#
# $HeadURL$
# $LastChangedRevision$
# $LastChangedDate$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';

use RPC::Serialized::Client::INET;

my $c = RPC::Serialized::Client::INET->new({
    io_socket_inet => { PeerAddr => '127.0.0.1', PeerPort => 1234 },
});

eval {
    my $res = $c->echo(qw(a b c d));
    print "echo: " . join( ":", @$res ) . "\n";
};
warn "$@\n" if $@;

eval {
    my $now = $c->localtime;
    print "Localtime: $now\n";
};
warn "$@\n" if $@;
