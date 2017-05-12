use strict;
use warnings;

use Test::More tests => 1;                      # last test to print
use Protocol::PostgreSQL::Client;

my @queue;
my $pg = new_ok('Protocol::PostgreSQL::Client' => [
	debug => 0,
	on_send_request	=> sub {
		my ($self, $msg) = @_;
		push @queue, $msg;
	},
]);


