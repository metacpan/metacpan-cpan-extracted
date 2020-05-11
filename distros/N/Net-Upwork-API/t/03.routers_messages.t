#!/usr/bin/env perl
use strict;
use Test::More tests => 11;
use lib qw(lib);
use Net::Upwork::API::Routers::Messages;

can_ok('Net::Upwork::API::Routers::Messages', 'new');
can_ok('Net::Upwork::API::Routers::Messages', 'get_rooms');
can_ok('Net::Upwork::API::Routers::Messages', 'get_room_details');
can_ok('Net::Upwork::API::Routers::Messages', 'get_room_messages');
can_ok('Net::Upwork::API::Routers::Messages', 'get_room_by_offer');
can_ok('Net::Upwork::API::Routers::Messages', 'get_room_by_application');
can_ok('Net::Upwork::API::Routers::Messages', 'get_room_by_contract');
can_ok('Net::Upwork::API::Routers::Messages', 'create_room');
can_ok('Net::Upwork::API::Routers::Messages', 'send_message_to_room');
can_ok('Net::Upwork::API::Routers::Messages', 'update_room_settings');
can_ok('Net::Upwork::API::Routers::Messages', 'update_room_metadata');
