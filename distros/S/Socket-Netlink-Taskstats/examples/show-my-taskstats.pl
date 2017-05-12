#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket::Netlink::Taskstats;

use Data::Dump qw( dump );

dump IO::Socket::Netlink::Taskstats->new->get_process_info_by_pid( @ARGV ? $ARGV[0] : $$ )
