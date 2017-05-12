package PITA::XML::Storable;

# A PITA::XML class that can be loaded from and saved to a file

use strict;
use Params::Util qw{ _INSTANCE };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.52';
}





#####################################################################
# Main Methods

sub read {
	my $class = shift;
	my $fh    = PITA::XML->_FH(shift);

	### NOTE: DISABLED TILL WE FINALIZE THE SCHEMA
	# Validate the document and reset the handle
	# $class->validate( $fh );
	# $fh->seek( 0, 0 ) or Carp::croak(
	#	'Failed to reset file after validation (seek to 0)'
	#	);

	# Build the object from the file and validate
	my $self   = bless { }, $class;
	my $parser = XML::SAX::ParserFactory->parser(
		Handler => PITA::XML::SAXParser->new( $self ),
	);
	$parser->parse_file($fh);

	return $self;
}

sub write {
	my $self = shift;

	# Prepate the driver params
	my @params = _INSTANCE($_[0], 'XML::SAX::Base')
		? ( Handler => shift )
		: defined($_[0])
			? ( Output  => shift )
			: Carp::croak("Did not provide an output destination to ->write");

	# Create the SAX Driver
	my $driver = PITA::XML::SAXDriver->new( @params );
	unless ( $driver ) {
		die("Failed to create SAXDriver for report");
	}

	# Parse ourself with the driver to driver the writing
	# of the output.
	$driver->parse( $self );

	return 1;
}

1;
