#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 1.0;

use lib qw(t/lib);
require 'setup_common.pl';

my $class = 'Module::Release';
subtest setup => sub {
	use_ok( $class );
	can_ok( $class, 'new' );
	};

my $release = $class->new;

like(
    $release->get_release_date,
    qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/,
    "Returns datetime in UTC as a string in required format"
	);

{
no warnings qw(redefine once);
local *Time::Piece::datetime = sub { '2017-09-02T10:05:49' };
local *Time::Piece::gmtime   = sub { 'Time::Piece' };
is( $release->get_release_date,
	'2017-09-02T10:05:49Z',
	"Returns known datetime as a string in required format" );
}

done_testing();
