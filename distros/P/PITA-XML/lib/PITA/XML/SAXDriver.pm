package PITA::XML::SAXDriver;

=pod

=head1 NAME

PITA::XML::SAXDriver - Implements a SAX Driver for PITA::XML objects

=head1 DESCRIPTION

Although you won't need to use it directly, this class provides a
"SAX Driver" class that converts a L<PITA::XML> object into a stream
of SAX events (which will mostly likely be written to a file).

Please note that this class is incomplete at this time. Although you
can create objects, you can't actually run them yet.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp           ();
use Params::Util   ':ALL';
use Class::Autouse 'XML::SAX::Writer';
use PITA::XML      ();
use XML::SAX::Base ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.52';
	@ISA     = 'XML::SAX::Base';
}





#####################################################################
# Constructor

=pod

=head2 new

  # Create a SAX Driver to generate in-memory
  $driver = PITA::XML::SAXDriver->new();
  
  # ... or to stream (write) to a file
  $driver = PITA::XML::SAXDriver->new( Output => 'filename' );
  
  # ... or to send the events to a custom handler
  $driver = PITA::XML::SAXDriver->new( Handler => $handler   );

The C<new> constructor creates a new SAX generator for PITA-XML files.

It takes a named param of B<EITHER> an XML Handler object, or an
C<Output> value that is compatible with L<XML::SAX::Writer>.

Returns a C<PITA::XML::SAXDriver> object, or dies on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless {
		NamespaceURI => PITA::XML->XMLNS,
		Prefix       => '',
		@_,
	}, $class;

	# Add a default SAX Handler
	unless ( $self->{Handler} ) {
		# We are going to create a file writer to anything
		# that it supports. So we will need an Output param.
		unless ( $self->{Output} ) {
			my $Output = '';
			$self->{Output} = \$Output;
		}

		# Create the file writer
		$self->{Handler} = XML::SAX::Writer->new(
			Output => $self->{Output},
		) or Carp::croak("Failed to create XML Writer for Output");
	}

	# Check the namespace
	unless ( _STRING($self->{NamespaceURI}) ) {
		Carp::croak("Invalid NamespaceURI");
	}

	# Flag that an xmlns attribute be added
	# to the first element in the document
	$self->{xmlns} = $self->{NamespaceURI};

	$self;
}

=pod

=head2 NamespaceURI

The C<NamespaceURI> returns the name of the XML namespace being used
in the file generation.

While PITA is still in development, this should be something like
the following, where C<$VERSION> is the L<PITA::XML> version string.

  http://ali.as/xml/schema/pita-xml/$VERSION

=cut

sub NamespaceURI {
	$_[0]->{NamespaceURI};
}

=pod

=head2 Prefix

The C<Prefix> returns the name of the XML prefix being used for the output.

=cut

sub Prefix {
	$_[0]->{Prefix};
}

=pod

=head2 Handler

The C<Handler> returns the SAX Handler object that the SAX events are being
sent to. This will be or the SAX Handler object you originally passed
in, or a L<XML::SAX::Writer> object pointing at your C<Output> value.

=cut

sub Handler {
	$_[0]->{Handler};
}

=pod

=head2 Output

If you did not provide a custom SAX Handler, the C<Output> accessor
returns the location you are writing the XML output to.

If you did not provide a C<Handler> or C<Output> param to the constructor,
then this returns a C<SCALAR> reference containing the XML as a string.

=cut

sub Output {
	$_[0]->{Output};
}





#####################################################################
# Main SAX Methods

# Prevent use as a SAX Filter or SAX Parser
# We only generate SAX events, we don't consume them.
#sub start_document {
#	my $class = ref $_[0] || $_[0];
#	die "$class is not a SAX Filter or Driver, it cannot recieve events";
#}

sub parse {
	my $self = shift;
	my $root = _INSTANCE(shift, 'PITA::XML::Storable');
	unless ( $root ) {
		Carp::croak("Did not provide a writable root object");
	}

	# Attach the xmlns to the first tag
	if ( $self->{NamespaceURI} ) {
		$self->{xmlns} = $self->{NamespaceURI};
	}

	# Generate the SAX2 events
	$self->start_document( {} );
	if ( _INSTANCE($root, 'PITA::XML::Report') ) {
		$self->_parse_report( $root );
	} elsif ( _INSTANCE($root, 'PITA::XML::Request') ) {
		$self->_parse_request( $root );
	} elsif ( _INSTANCE($root, 'PITA::XML::Guest') ) {
		$self->_parse_guest( $root );
	} else {
		die("Support for " . ref($root) . " not implemented");
	}
	$self->end_document( {} );

	return 1;
}

sub start_document {
	my $self = shift;

	# Do the normal start_document tasks
	$self->SUPER::start_document( @_ );

	# And always put the XML declaration at the start
	$self->xml_decl( {
		Version  => '1.0',
		Encoding => 'UTF-8',
	} );

	return 1;
}

# Generate events for the parent PITA::XML::Report object
sub _parse_report {
	my $self   = shift;
	my $report = shift;

	# Send the open tag
	my $element = $self->_element( 'report' );
	$self->start_element( $element );

	# Iterate over the individual installations
	foreach my $install ( $report->installs ) {
		$self->_parse_install( $install );
	}

	# Send the close tag
	$self->end_element($element);

	return 1;
}

# Generate events for a single install
sub _parse_install {
	my $self    = shift;
	my $install = shift;

	# Send the open tag
	my $element = $self->_element( 'install' );
	$self->start_element( $element );

	# Send the optional configuration tag
	$self->_parse_request( $install->request );

	# Send the optional platform tag
	$self->_parse_platform( $install->platform );

	# Add the command tags
	foreach my $command ( $install->commands ) {
		$self->_parse_command( $command );
	}

	# Add the test tags
	foreach my $test ( $install->tests ) {
		$self->_parse_test( $test );
	}

	# Add the optional analysis tag
	my $analysis = $install->analysis;
	if ( $analysis ) {
		$self->_parse_analysis( $analysis );
	}

	# Send the close tag
	$self->end_element( $element );

	return 1;
}

# Generate events for a request
sub _parse_request {
	my $self    = shift;
	my $request = shift;

	# Send the open tag
	my $attr = $request->id
		? { id => $request->id }
		: { };
	my $element = $self->_element( 'request', $attr );
	$self->start_element( $element );

	# Send the main accessors
	$self->_accessor_element( $request, 'scheme'   );
	$self->_accessor_element( $request, 'distname' );

	# Send the file(s)
	$self->_parse_file( $request->file );

	# Send the optional authority information
	if ( $request->authority ) {
		$self->_accessor_element( $request, 'authority' );
		if ( $request->authpath ) {
			$self->_accessor_element( $request, 'authpath' );
		}
	}

	# Send the close tag
	$self->end_element( $element );

	return 1;
}

# Generate events for a guest
sub _parse_guest {
	my $self  = shift;
	my $guest = shift;

	# Send the open tag
	my $attr = $guest->id
		? { id => $guest->id }
		: { };
	my $element = $self->_element( 'guest', $attr );
	$self->start_element( $element );

	# Send the main accessors
	$self->_accessor_element( $guest, 'driver' );

	# Iterate over the individual files
	foreach my $file ( $guest->files ) {
		$self->_parse_file( $file );
	}

	# Send each of the config variables
	my $config = $guest->config;
	foreach my $name ( sort keys %$config ) {
		my $el = $self->_element( 'config', { name => $name } );
		$self->start_element( $el );
		defined($config->{$name})
			? $self->characters( $config->{$name} )
			: $self->_undef;
		$self->end_element( $el );
	}

	# Iterate over the individual platforms
	foreach my $platform ( $guest->platforms ) {
		$self->_parse_platform( $platform );
	}

	# Send the close tag
	$self->end_element($element);

	return 1;
}

# Generate events for a file
sub _parse_file {
	my $self = shift;
	my $file = shift;

	# Send the open tag
	my $element = $self->_element( 'file' );
	$self->start_element( $element );

	# Send the main accessors
	$self->_accessor_element( $file, 'filename' );

	# Send the optional resource name
	if ( defined $file->resource ) {
		my $el = $self->_element( 'resource' );
		$self->start_element( $el );
		$self->characters( $file->resource );
		$self->end_element( $el );
	}

	# Send the optional digest
	if ( defined $file->digest ) {
		my $el = $self->_element( 'digest' );
		$self->start_element( $el );
		$self->characters( $file->digest->as_string );
		$self->end_element( $el );
	}

	# Send the close tag
	$self->end_element( $element );

	return 1;
}

# Generate events for a platform configuration
sub _parse_platform {
	my $self     = shift;
	my $platform = shift;

	# Send the open tag
	my $element = $self->_element( 'platform' );
	$self->start_element( $element );

	# Send the scheme
	if ( $platform->scheme ) {
		my $el = $self->_element( 'scheme' );
		$self->start_element( $el );
		$self->characters( $platform->scheme );
		$self->end_element( $el );
	}

	# Send the path
	if ( $platform->path ) {
		my $el = $self->_element( 'path' );
		$self->start_element( $el );
		$self->characters( $platform->path );
		$self->end_element( $el );
	}

	# Send each of the environment variables
	my $env = $platform->env;
	foreach my $name ( sort keys %$env ) {
		my $el = $self->_element( 'env', { name => $name } );
		$self->start_element( $el );
		defined($env->{$name})
			? $self->characters( $env->{$name} )
			: $self->_undef;
		$self->end_element( $el );
	}

	# Send each of the config variables
	my $config = $platform->config;
	foreach my $name ( sort keys %$config ) {
		my $el = $self->_element( 'config', { name => $name } );
		$self->start_element( $el );
		defined($config->{$name})
			? $self->characters( $config->{$name} )
			: $self->_undef;
		$self->end_element( $el );
	}

	# Send the close tag
	$self->end_element( $element );

	return 1;
}

sub _parse_command {
	my $self    = shift;
	my $command = shift;

	# Send the open tag
	my $element = $self->_element( 'command' );
	$self->start_element( $element );

	# Send the accessors
	$self->_accessor_element( $command, 'cmd'    );
	$self->_accessor_element( $command, 'stdout' );
	$self->_accessor_element( $command, 'stderr' );

	# Send the close tag
	$self->end_element( $element );

	return 1;
}

sub _parse_test {
	my $self = shift;
	my $test = shift;

	# Send the open tag
	my $attrs = {
		language => $test->language,
	};
	if ( defined $test->name ) {
		$attrs->{name} = $test->name;
	}
	my $element = $self->_element( 'test', $attrs );
	$self->start_element( $element );

	# Send the accessor elements
	$self->_accessor_element( $test, 'stdout' );
	if ( defined $test->stderr ) {
		$self->_accessor_element( $test, 'stderr' );
	}
	if ( defined $test->exitcode ) {
		$self->_accessor_element( $test, 'exitcode' );
	}

	# Send the close tag
	$self->end_element( $element );

	return 1;
}

sub _parse_analysis {
	die "CODE INCOMPLETE";
}

# Specifically send an undef tag pair
sub _undef {
	my $self = shift;
	my $el   = $self->_element('null');
	$self->start_element( $el );
	$self->end_element( $el );
}





#####################################################################
# Support Methods

# Make sure the first element gets an xmlns attribute
sub start_element {
	my $self    = shift;
	my $element = shift;
	my $xmlns   = delete $self->{xmlns};

	# Shortcut for the most the common case
	unless ( $xmlns ) {
		return $self->SUPER::start_element( $element );
	}

	# Add the XMLNS Attribute
	$element->{Attributes}->{'xmlns'} = {
		Prefix    => '',
		LocalName => 'xmlns',
		Name      => 'xmlns',
		Value     => $xmlns,
	};

	# Pass on to the parent class
	$self->SUPER::start_element( $element );
}

# Strip out the Attributes for the end element
sub end_element {
	delete $_[1]->{Attributes};
	shift->SUPER::end_element(@_);
}

sub _element {
	my $self       = shift;
	my $LocalName  = shift;
	my $attrs      = _HASH(shift) || {};

	# Localise some variables for speed
	my $NamespaceURI = $self->{NamespaceURI};
	my $Prefix       = $self->{Prefix}
		? "$self->{Prefix}:"
		: '';

	# Convert the attributes to the full version
	my %Attributes = ();
	if ( $attrs->{xmlns} ) {
		# The xmlns attribute is always first
		my $value = delete $attrs->{xmlns};
		$Attributes{xmlns} = {
			Name         => 'xmlns',
			#NamespaceURI => $NamespaceURI,
			#Prefix       => $Prefix,
			#LocalName    => $key,
			Value        => $value,
		};
	}
	foreach my $key ( sort keys %$attrs ) {
		#$Attributes{"{$NamespaceURI}$key"} = {
		$Attributes{$key} = {
			Name         => $Prefix . $key,
			#NamespaceURI => $NamespaceURI,
			#Prefix       => $Prefix,
			#LocalName    => $key,
			Value        => $attrs->{$key},
		};
	}

	# Complete the main element
	return {
		Name         => $Prefix . $LocalName,
		#NamespaceURI => $NamespaceURI,
		#Prefix       => $Prefix,
		#LocalName    => $LocalName,
		Attributes   => \%Attributes,
	};
}

# Send a matching tag for a known object accessor
sub _accessor_element {
	my $self   = shift;
	my $object = shift;
	my $method = shift;
	my $value  = $object->$method();

	# Generate the element and send it
	my $el = $self->_element( $method );
	$self->start_element( $el );
	$self->characters( $value );
	$self->end_element( $el );
}

# Auto-preparation of the text
sub characters {
	my $self = shift;

	# A { Data => '...' } string
	if ( _HASH($_[0]) ) {
		return $self->SUPER::characters(shift);
	}

	# A normal string, by reference
	if ( _SCALAR0($_[0]) ) {
		my $scalar_ref = shift;
		return $self->SUPER::characters( {
			Data => $$scalar_ref,
		} );
	}

	# Must be a normal string
	$self->SUPER::characters( {
		Data => shift,
	} );
}

### Not sure if we escape here.
### Just pass through for now.
sub _escape { $_[1] }

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-XML>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<PITA::XML>, L<PITA::XML::SAXParser>

The Perl Image-based Testing Architecture (L<http://ali.as/pita/>)

=head1 COPYRIGHT

Copyright 2005 - 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
