#!/usr/bin/perl

########################################################################
# this test simply tests the Test::DatabaseRow::Result object
########################################################################

use strict;
use warnings;

use Test::More tests => 10;

BEGIN { use_ok("Test::DatabaseRow::Result") };


{
	my $result = Test::DatabaseRow::Result->new();
	isa_ok($result, "Test::DatabaseRow::Result");
	ok(!$result->is_error, "Not is_error");
	ok($result->is_success, "Is is_success");
	is_deeply($result->diag, [], "diag");
}
{
	my $result = Test::DatabaseRow::Result->new( is_error => 1, diag => [ "foo", "bar" ]);
	isa_ok($result, "Test::DatabaseRow::Result");
	ok($result->is_error, "Is is_error");
	ok(!$result->is_success, "Not is_success");
	is_deeply($result->diag, [ "foo", "bar" ], "diag");
	$result->add_diag("bazz","buzz");
	is_deeply($result->diag, [ "foo", "bar","bazz","buzz" ], "diag");
}