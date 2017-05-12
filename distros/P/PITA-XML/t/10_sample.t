#!/usr/bin/perl

# Unit tests for the PITA::XML::Platform class

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use File::Spec::Functions ':ALL';
use PITA::XML ();

# Extra testing functions
sub dies {
	my $code = shift;
	eval { &$code() };
	ok( $@, $_[0] || 'Code dies as expected' );
}

sub dies_like {
	my $code   = shift;
	my $regexp = shift;
	eval { &$code() };
	like( $@, $regexp, $_[0] || 'Core dies like expected' );
}





#####################################################################
# Create sample data

my $XMLNS = PITA::XML->XMLNS;
ok( $XMLNS, 'Got XML namespace' );

my $EMPTY_FILE = catfile( 't', 'samples', 'empty.pita'   );
ok( -f $EMPTY_FILE, 'Sample empty.pita file exists'      );
ok( -f $EMPTY_FILE, 'Sample empty.pita file is readable' );

my $SINGLE_FILE = catfile( 't', 'samples', 'single.pita'   );
ok( -f $SINGLE_FILE, 'Sample single.pita file exists'      );
ok( -f $SINGLE_FILE, 'Sample single.pita file is readable' );

# Create some documents a plan text

my $empty_report = <<"END_XML";
<?xml version="1.0" encoding="ISO-8859-1"?><report xmlns='$XMLNS' />
END_XML

my $empty_request = <<"END_XML";
<?xml version="1.0" encoding="ISO-8859-1"?><request xmlns='$XMLNS' />
END_XML





#####################################################################
# Validation

SKIP: {
	skip("Tests out of date", 3 );

	ok( PITA::XML->validate( \"<report xmlns='$XMLNS' />" ),
		'Sample (empty) string validates' );
	ok( PITA::XML->validate( $EMPTY_FILE ),
		'Sample (empty) file validates' );
	ok( PITA::XML->validate( $SINGLE_FILE ),
		'Sample (single) file validates' );
}





#####################################################################
# Practical Parsing Test

# Create some sample objects from minimal strings
SCOPE: {
	my $report = PITA::XML::Report->read( \$empty_report );
	isa_ok( $report, 'PITA::XML::Report' );
	is( scalar($report->installs), 0, '->installs returns zero' );
	is_deeply( [ $report->installs ], [], '->installs returns null list' );
}

# Shouldn't be able to create something from just a request
# This should die somehow...
dies( sub { PITA::XML::Request->read(
	\$empty_request,
	) },
	'->new(bad request xml) dies as expected',
);
