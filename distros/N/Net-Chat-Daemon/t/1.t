# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 1;
BEGIN { use_ok('Net::Chat::Daemon') };

# I need to figure out how to ask the user if it's ok to send test
# messages, and to enter a jabber id.
