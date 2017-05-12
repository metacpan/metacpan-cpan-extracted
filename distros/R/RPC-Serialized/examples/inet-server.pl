#!/usr/bin/perl
#
# $HeadURL$
# $LastChangedRevision$
# $LastChangedDate$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';

use RPC::Serialized::Server::NetServer::Single;

my $s = RPC::Serialized::Server::NetServer::Single->new({
    net_server => { port => 1234 },
});

$s->run;
