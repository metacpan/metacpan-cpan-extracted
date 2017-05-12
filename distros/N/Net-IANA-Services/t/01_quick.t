#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 20;
use Net::IANA::Services qw/ :all /;

#  Not all encompassing... just need to ship this quick

is 22        =~ $IANA_REGEX_PORTS          , 1, 'port regex okay';
is 9         =~ $IANA_REGEX_PORTS_DCCP     , 1, 'dccp port regex okay';
is 9         =~ $IANA_REGEX_PORTS_SCTP     , 1, 'sctp port regex okay';
is 22        =~ $IANA_REGEX_PORTS_TCP      , 1, 'tcp  port regex okay';
is 53        =~ $IANA_REGEX_PORTS_UDP      , 1, 'udp  port regex okay';

is 'ssh'     =~ $IANA_REGEX_SERVICES       , 1, 'service regex okay';
is 'discard' =~ $IANA_REGEX_SERVICES_DCCP  , 1, 'dccp service regex okay';
is 'discard' =~ $IANA_REGEX_SERVICES_SCTP  , 1, 'sctp service regex okay';
is 'ssh'     =~ $IANA_REGEX_SERVICES_TCP   , 1, 'tcp  service regex okay';
is 'domain'  =~ $IANA_REGEX_SERVICES_UDP   , 1, 'udp  service regex okay';

is $IANA_HASH_INFO_FOR_SERVICE->{ ssh }{ tcp }{22}{ name }, 'ssh', 'SSH defined correctly';
is $IANA_HASH_PORTS_FOR_SERVICE->{ ssh }->[0]             , 22   , 'known ports for ssh correct';
is $IANA_HASH_SERVICES_FOR_PORT->{22}->[0]                , 'ssh', 'service for port okay';
is $IANA_HASH_SERVICES_FOR_PORT_PROTO->{22}{tcp}->[0]     , 'ssh', 'service for port okay';

is iana_has_port           ( 22  ), 1, 'has_port sub okay';
is iana_has_service        ('ssh'), 1, 'has_port sub okay';

is iana_info_for_port(22)->[0]                      , 'ssh', 'info_port sub okay';
is iana_info_for_port(22, 'tcp')->[0]               , 'ssh', 'info_port_proto sub okay';
is iana_info_for_service('ssh')->{'tcp'}{22}{'name'}, 'ssh', 'info_service okay';
is iana_info_for_service('ssh', 'tcp')->{22}{'name'}, 'ssh', 'info_service_proto okay';
