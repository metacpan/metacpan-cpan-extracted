use strict;
use warnings;

use Test::More tests => 1017;
use Protocol::IMAP::Client;

# Basic class structure
{
	my $imap = new_ok('Protocol::IMAP::Client');
	ok($imap->STATE_HANDLERS, 'have state handlers');
	like($_, qr/^on_/, "state handler $_ has on_ prefix") for $imap->STATE_HANDLERS;
	can_ok($imap, $_) for qw{debug state write new};
}

# ID handling
{
	my %seen;
	my $imap = new_ok('Protocol::IMAP::Client');
	foreach (0..500) {
		my $id = $imap->next_id;
		ok(!exists $seen{$id}, 'id is unique');
		ok(length $id, 'id has nonzero length');
		++$seen{$id};
	}
}

# State handling
{
	package Protocol::IMAP::Test;
	use parent qw{Protocol::IMAP};

	package main;
	my $imap = new_ok('Protocol::IMAP::Test');
}
