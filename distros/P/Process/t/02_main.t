#!/usr/bin/perl

# Main tests

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Spec::Functions ':ALL';





#####################################################################
# Test the base Process class

use Process;
SCOPE: {
	my $object = Process->new;
	isa_ok( $object, 'Process' );
	ok( $object->prepare, '->prepare returns true' );
	ok( $object->run,     '->run returns true'     );
}





#####################################################################
# Test a simple subclass

use t::lib::MySimpleProcess;
SCOPE: {
	my $object = t::lib::MySimpleProcess->new( foo => 'bar' );
	isa_ok( $object, 't::lib::MySimpleProcess', 'Process' );
	is( $object->{foo}, 'bar', 'Sets ->{foo} to bar'   );
	ok( $object->prepare, '->prepare returns true'     );
	ok( $object->run,     '->run returns true'         );
	is( $object->{prepare}, 1, 'Sets ->{prepare} to 1' );
	is( $object->{run},     1, 'Sets ->{run} to 1'     );	
}
