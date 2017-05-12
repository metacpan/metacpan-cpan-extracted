#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use File::Spec::Functions ':ALL';
use Module::Changes::ADAMK;





#####################################################################
# Parse all stored files

my $data = catdir('t', 'data');
ok( -d $data, 'Found data directory' );
opendir( DIR, $data ) or die("opendir: $!");
my @files = grep { -f $_ } map { catfile($data, $_) } sort readdir( DIR );
foreach my $file ( @files ) {
	ok( -f $file, "File ok '$file'" );

	my $changes = eval {
		Module::Changes::ADAMK->read($file);
	};
	ok( ! $@, "$file parses without an error" );
	isa_ok( $changes, 'Module::Changes::ADAMK' );
}
