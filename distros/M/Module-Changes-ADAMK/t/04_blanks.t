#!/usr/bin/perl

# Test a Changes file with unexpected blank lines.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 20;
use File::Spec::Functions ':ALL';
use Module::Changes::ADAMK;





# Create the changes object
my $object = Module::Changes::ADAMK->read_string(<<'END_CHANGES');
Revisions for Perl extension My-Foo

0.02 Mon 13 Apr 2009
	- Line one

	- Line two

0.01 Mon 13 Apr 2009
	- Line one
END_CHANGES
isa_ok( $object, 'Module::Changes::ADAMK' );
is( $object->dist_name,   'My-Foo',  '->dist_name ok'   );
is( $object->module_name, 'My::Foo', '->module_name ok' );
my @releases = $object->releases;
is( scalar(@releases), 2, 'Found 2 releases' );
isa_ok( $releases[0],     'Module::Changes::ADAMK::Release' );
isa_ok( $releases[1],     'Module::Changes::ADAMK::Release' );
isa_ok( $object->current, 'Module::Changes::ADAMK::Release' );
is( $object->current_version,  '0.02', '->current_version ok' );
is( $object->current->version, '0.02', '->current->version matches' );
is( $object->current->date, 'Mon 13 Apr 2009', '->current->date ok' );
my @changes = $releases[0]->changes;
is( scalar(@changes), 2, 'Found 2 changes' );
isa_ok( $changes[0], 'Module::Changes::ADAMK::Change' );
isa_ok( $changes[1], 'Module::Changes::ADAMK::Change' );
is( $changes[0]->message, 'Line one', 'Line one ok' );
is( $changes[1]->message, 'Line two', 'Line two ok' );
foreach ( @changes, @releases, $object ) {
	ok( $_->roundtrips, '->roundtrips ok' );
}
