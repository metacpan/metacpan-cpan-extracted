#!/usr/bin/perl -T

use strict;
use warnings 'all';

use Test::More tests => 14;
use Test::Fatal;

use Net::SAJAX;
use URI;

###########################################################################
# EMPTY CONSTRUCTOR
# Expect: Failure
{
	isnt(exception { Net::SAJAX->new }, undef, 'Empty constructor does not succeed');
}

###########################################################################
# CONSTRUCTOR WITH BAD ARGUMENTS
# Expect: Failure
{
	isnt(exception { Net::SAJAX->new(i_am_a_bad_argument => 1) }, undef,
		'Constructor with unknown argument failes');
}

###########################################################################
# CONSTRUCTOR WITH URL STRING
# Expect: Success
{
	my $url = 'http://example.net/sajax_app.php';

	my $sajax = new_ok('Net::SAJAX' => [
		url => $url,
	]);

	is($sajax->url, $url, 'URL successfully accessed');
}

###########################################################################
# CONSTRUCTOR WITH URL OBJECT
# Expect: Success
{
	my $url = 'http://example.net/sajax_app.php';

	my $sajax = new_ok('Net::SAJAX' => [
		url => URI->new($url),
	]);

	is($sajax->url, $url, 'URL successfully accessed');
}

###########################################################################
# CONSTRUCTOR WITH ALL ARGUMENTS
# Expect: Success
{
	my $send_rand_key = 0;
	my $target_id     = 'some_target';
	my $url           = 'http://example.net/sajax_app.php';

	my $sajax = new_ok('Net::SAJAX' => [
		send_rand_key => $send_rand_key,
		target_id     => $target_id,
		url           => $url,
	], 'Complete construction using HASH');

	is($sajax->send_rand_key, $send_rand_key, 'Rand key sending successfully accessed');
	is($sajax->target_id    , $target_id    , 'Target ID successfully accessed');
	is($sajax->url          , $url          , 'URL successfully accessed');
}

###########################################################################
# CONSTRUCTOR WITH ALL ARGUMENTS IN HASHREF
# Expect: Success
{
	my $send_rand_key = 0;
	my $target_id     = 'some_target';
	my $url           = 'http://example.net/sajax_app.php';

	my $sajax = new_ok('Net::SAJAX' => [{
		send_rand_key => $send_rand_key,
		target_id     => $target_id,
		url           => $url,
	}], 'Construction using HASHREF');

	is($sajax->send_rand_key, $send_rand_key, 'Rand key sending successfully accessed');
	is($sajax->target_id    , $target_id    , 'Target ID successfully accessed');
	is($sajax->url          , $url          , 'URL successfully accessed');
}
