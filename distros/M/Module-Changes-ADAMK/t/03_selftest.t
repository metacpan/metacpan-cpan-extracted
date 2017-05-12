#!/usr/bin/perl

# Yes, you need to update this every release.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 27;
use Module::Changes::ADAMK;





#####################################################################
# Parse our own Changes file

ok( -f 'Changes', 'Found Changes file' );
my $changes = Module::Changes::ADAMK->read('Changes');
isa_ok( $changes, 'Module::Changes::ADAMK' );
is( $changes->dist_name,   'Module-Changes-ADAMK',  '->dist_name ok'   );
is( $changes->module_name, 'Module::Changes::ADAMK', '->module_name ok' );
my $current = $changes->current;
isa_ok( $current, 'Module::Changes::ADAMK::Release' );
is( $current->version, '0.11', '->version ok' );
is( $current->date, 'Sun 19 Apr 2009', '->date ok' );
my @changes = $current->changes;
is( scalar(@changes), 1, 'Found 1 changes' );
my $change = $changes[0];
isa_ok( $change, 'Module::Changes::ADAMK::Change' );
is( $change->author, 'ADAMK', '->author ok' );
is( $change->message, 'Ignore empty paragraphs', '->message ok' );





#####################################################################
# Round-Trip Testing for Releases

foreach ( $changes->releases ) {
	ok( $_->roundtrips, 'Roundtrip ' . $_->version . ' ok' );
}





#####################################################################
# Change a release date

# Round-trip testing
ok(
	$current->as_string eq $current->string,
	'Change round-trip stringification ok',
);
ok(
	$changes->as_string eq $changes->string,
	'File round-trip stringification ok',
);
ok(
	$current->set_datetime(
		DateTime->now->add( days => 2 )
	),
	'->set_datetime_now ok',
);
ok(
	$current->as_string ne $current->string,
	'Date was changed (' . $current->date . ')',
);
ok(
	$changes->as_string ne $changes->string,
	'File was changed',
);
