use strict;
use warnings;

use Test::More tests => 18;
use Protocol::IMAP;

ok((1 == grep { $_ eq 'ConnectionClosed' } @Protocol::IMAP::STATES), "Have ConnectionClosed state");
ok((1 == grep { $_ eq 'ConnectionEstablished' } @Protocol::IMAP::STATES), "Have ConnectionEstablished state");
ok((1 == grep { $_ eq 'ServerGreeting' } @Protocol::IMAP::STATES), "Have ServerGreeting state");
ok((1 == grep { $_ eq 'NotAuthenticated' } @Protocol::IMAP::STATES), "Have NotAuthenticated state");
ok((1 == grep { $_ eq 'Authenticated' } @Protocol::IMAP::STATES), "Have Authenticated state");
ok((1 == grep { $_ eq 'Selected' } @Protocol::IMAP::STATES), "Have Selected state");
ok((1 == grep { $_ eq 'Logout' } @Protocol::IMAP::STATES), "Have Logout state");
is(values(%Protocol::IMAP::STATE_BY_ID), @Protocol::IMAP::STATES, 'have correct number of states in state map');
is(@Protocol::IMAP::STATES, values(%{ +{ reverse %Protocol::IMAP::STATE_BY_ID } }), 'state map entries are all unique');

my $imap = new_ok('Protocol::IMAP');
ok($imap->STATE_HANDLERS, 'have state handlers');
like($_, qr/^on_/, "state handler $_ has on_ prefix") for $imap->STATE_HANDLERS;

