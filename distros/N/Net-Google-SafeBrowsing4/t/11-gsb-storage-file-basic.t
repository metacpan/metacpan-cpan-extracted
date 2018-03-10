#!/usr/bin/perl

# ABSTRACT: Basic tests about the Net::Google::SafeBrowsing4::Storage::File class

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
	use_ok("Net::Google::SafeBrowsing4::Storage::File");
};

require_ok("Net::Google::SafeBrowsing4::Storage::File");

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

can_ok("Net::Google::SafeBrowsing4::Storage::File", @methods);
