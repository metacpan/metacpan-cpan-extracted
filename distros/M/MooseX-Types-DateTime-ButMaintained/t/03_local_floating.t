#!/usr/bin/perl


package Class;
use Moose;
use strict;
use warnings;

use MooseX::Types::DateTime::ButMaintained qw(TimeZone);

has 'tz' => ( isa => TimeZone, is => 'rw', coerce => 1 );

package main;
use Test::More tests => 3;

my $o = Class->new;

foreach my $tz ( 'floating', 'America/Chicago' ) {
	eval {
		$o->tz( $tz );
	};
	ok( ! $@, "'$tz' timezone worked" );
}


## Not all systems can use local (has to successfuly detect)
eval { DateTime::TimeZone->new( name => 'local' ) };
SKIP: {
	skip "DateTime::TimeZone's local doesn't work on your system", 1 if $@;
	eval { $o->tz( 'local' ) };
	ok( ! $@, "'local' timezone worked" );
}

1;
