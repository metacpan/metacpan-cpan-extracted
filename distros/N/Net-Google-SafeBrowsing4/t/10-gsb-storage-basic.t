#!/usr/bin/perl

# ABSTRACT: Basic tests about the Net::Google::SafeBrowsing4::Storage interface class

use strict;
use warnings;

use Test::Exception;
use Test::More qw(no_plan);

BEGIN {
	use_ok("Net::Google::SafeBrowsing4::Storage");
};

require_ok("Net::Google::SafeBrowsing4::Storage");

my @methods = qw{
	new
	save
	reset
	next_update
	get_state
	get_prefixes
	updated
	get_full_hashes
	update_error
	last_update
	add_full_hashes
	full_hash_error
	full_hash_ok
	get_full_hash_error
	get_lists
	save_lists
};

can_ok("Net::Google::SafeBrowsing4::Storage", @methods);

foreach my $method (@methods) {
	throws_ok { Net::Google::SafeBrowsing4::Storage->$method } qr/Unimplemented/, 'Abstract method ' . $method . 'should be re-defined';
}
