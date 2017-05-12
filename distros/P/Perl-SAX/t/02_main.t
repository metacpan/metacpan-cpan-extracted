#!/usr/bin/perl

# Formal testing for Perl::SAX

# The main test file, which for now means making sure ->new creates an object

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use File::Spec::Functions ':ALL';
use PPI       ();
use Perl::SAX ();

my $testfile = catfile( 't', 'data', '01_tiny.perl' );

# Create a new, default, object
my $Driver = Perl::SAX->new;
isa_ok( $Driver, 'Perl::SAX' );

# Load the test document
my $Document = PPI::Document->new( $testfile );
isa_ok( $Document, 'PPI::Document' );

# Do the parsing
ok( $Driver->parse( $Document ), '->parse returns true' );

# Get the results
my $Output = $Driver->{Output};
ok( ref $Output eq 'SCALAR', 'SCALAR output found' );
is( length $$Output, 793, 'Output is the correct length' );
