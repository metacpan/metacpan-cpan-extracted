#!/usr/bin/perl

# Main testing for Template::Plugin::Tooltip

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}




# Does everything load?
use Test::More tests => 4;

use Template::Plugin::Tooltip ();
use Template                  ();
use Template::Context         ();

# Create the test template context
my $context = Template::Context->new( {} );
if ( $Template::Context::ERROR ) {
	print "# $Template::Context::ERROR\n";
}
isa_ok( $context, 'Template::Context' );

# Create a standard object
my $Plugin = Template::Plugin::Tooltip->new( $context );
is( ref $Plugin, 'CODE', 'Template::Plugin::Tooltip->new returns a CODE reference' );

# Generate a basic tooltip
my $tooltip  = &{$Plugin}('This is a tooltip');
my $expected = ' onmouseover="return escape(\'This is a tooltip\');" ';
is( $tooltip, $expected, 'Tooltip HTML is correct' );

my $head = &{$Plugin}();
is( $head, '<SCRIPT LANGUAGE="Javascript" TYPE="text/javascript" src="/wz_tooltip.js"></SCRIPT>',
	'Got header HTML as expected' );

1;
