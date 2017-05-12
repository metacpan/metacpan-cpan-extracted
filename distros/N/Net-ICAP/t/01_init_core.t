#!/usr/bin/perl -T
# 01_init_core.t

use Test::More tests => 5;

use strict;
use warnings;

ok( eval 'require Net::ICAP::Common;',   'Loaded Net::ICAP::Common' );
ok( eval 'require Net::ICAP::Message;',  'Loaded Net::ICAP::Message' );
ok( eval 'require Net::ICAP::Request;',  'Loaded Net::ICAP::Request' );
ok( eval 'require Net::ICAP::Response;', 'Loaded Net::ICAP::Response' );
ok( eval 'require Net::ICAP::Server;',   'Loaded Net::ICAP::Server' );

# end 01_init_core.t
