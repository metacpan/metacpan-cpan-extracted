package PITA::XML::SAXParser;

=pod

=head1 NAME

PITA::XML::SAXParser - Implements a SAX Parser for PITA::XML files

=head1 DESCRIPTION

Although you won't need to use it directly, this class provides a
"SAX Parser" class that converts a stream of SAX events (most likely from
an XML file) and populates a L<PITA::XML> with L<PITA::XML::Install>
objects.

Please note that this class is incomplete at this time. Although you
can create objects and parse some of the tags, many are still ignored
at this time (in particular the E<lt>outputE<gt> and E<lt>analysisE<gt>
tags.

=head1 METHODS

In addition to the following documented methods, this class implements
a large number of methods relating to its implementation of a
L<XML::SAX::Base> subclass. These are not considered part of the
public API, and so are not documented here.

=cut

use strict;
use Carp           ();
use Params::Util   qw{ _INSTANCE };
use XML::SAX::Base ();

use vars qw{$VERSION @ISA $XML_NAMESPACE @PROPERTIES %TRIM};
BEGIN {
	$VERSION = '0.52';
	@ISA     = 'XML::SAX::Base';

	# Define the XML namespace we are a parser for
	$XML_NAMESPACE = 'http://ali.as/xml/schemas/PITA/1.0';

	# The name/tags for the simple properties
	@PROPERTIES = qw{
		id         driver
		scheme     distname
		filename   resource  digest
		authority  authpath
		cmd        path      system
		exitcode
	};

	# Set up the char strings to trim
	%TRIM = map { $_ => 1 } @PROPERTIES;

	# Create the property handlers
	foreach my $name ( @PROPERTIES ) { eval <<"END_PERL" }

	# Start capturing chars
	sub start_element_${name} {
		\$_[0]->{chars} = '';
		1;
	}

	# Save those chars to the element
	sub end_element_${name} {
		my \$self = shift;

		# Add the $name to the context
		\$self->_context->{$name} = delete \$self->{chars};

		1;
	}
END_PERL
}





#####################################################################
# Constructor

=pod

=head2 new

  # Create the SAX parser
  my $parser = PITA::XML::SAXParser->new( $report );

The C<new> constructor takes a single L<PITA::XML> object and creates
a SAX Parser for it. When used, the SAX Parser object will fill the empty
L<PITA::XML> object with L<PITA::XML::Install> reporting objects.

If used with a L<PITA::XML> that already has existing content, it
will add the new install reports in addition to the existing ones.

Returns a new C<PITA::XML::SAXParser> object, or dies on error.

=cut

sub new {
	my $class  = shift;
	my $root   = _INSTANCE(shift, 'PITA::XML::Storable');
	unless ( $root ) {
		Carp::croak("Did not provide a PITA::XML::Storable root element");
	}

	# Create the basic parsing object
	my $self = bless {
		object  => $root,
		root    => $root->xml_entity,
		context => [],
	}, $class;

	$self;
}

# Add to the context
sub _push {
	push @{shift->{context}}, @_;
	return 1;
}

# Remove from the context
sub _pop {
	my $self = shift;
	unless ( @{$self->{context}} ) {
		die "Ran out of context";
	}
	return pop @{$self->{context}};
}

# Get the current context
sub _context {
	shift->{context}->[-1];
}

# Convert full Attribute data into a simple hash
sub _hash {
	my $self  = shift;
	my $attrs = shift;

	# Shrink it
	my %hash  = map {
		$_->{LocalName}, $_->{Value}
	} grep {
		$_->{Value} =~ s/^\s+//;
		$_->{Value} =~ s/\s+$//;
		1;
	} grep {
		not $_->{Prefix}
	} values %$attrs;

	return \%hash;
}





#####################################################################
# Simplification Layer

sub start_element {
	my $self    = shift;
	my $element = shift;

	# We don't support namespaces.
	if ( $element->{Prefix} ) {
		Carp::croak(
			__PACKAGE__ .
			' does not support the use of XML namespaces (yet)',
		);
	}

	# If this is the root element, set up the initial context.
	# (and thus don't use the normal handler)
	unless ( @{$self->{context}} ) {
		unless ( $element->{LocalName} eq $self->{root} ) {
			Carp::croak( "Root element must be a <$self->{root}>" );
		}

		# Support ids in the root object
		my $hash = $self->_hash($element->{Attributes});
		if ( defined $hash->{id} ) {
			$self->{object}->{id} = $hash->{id};
		}

		# Set up the root object as the root context
		$self->_push( $self->{object} );
		return 1;
	}

	# Shortcut if we don't implement a handler
	my $handler = 'start_element_' . $element->{LocalName};
	return 1 unless $self->can($handler);

	# Hand off to the handler
	my $hash = $self->_hash($element->{Attributes});
	return $self->$handler( $hash );
}

sub end_element {
	my $self    = shift;
	my $element = shift;

	# Handle the closing root element
	if ( $element->{LocalName} eq $self->{root} and @{$self->{context}} == 1 ) {
		$self->_pop->_init;
		return 1;
	}

	# Hand off to the optional tag-specific handler
	my $handler = 'end_element_' . $element->{LocalName};
	return 1 unless $self->can($handler);

	# If there is anything in the character buffer, trim whitespace
	if ( exists $self->{chars} and defined $self->{chars} ) {
		if ( $TRIM{$element->{LocalName}} ) {
			$self->{chars} =~ s/^\s+//;
			$self->{chars} =~ s/\s+$//;
		}
	}

	return $self->$handler();
}

# Because we don't know in what context this will be called,
# we just store all character data in a character buffer
# and deal with it in the various end_element methods.
sub characters {
	my $self    = shift;
	my $element = shift;

	# Add to the buffer (if not null)
	if ( exists $self->{chars} and defined $self->{chars} ) {
		$self->{chars} .= $element->{Data};
	}

	return 1;
}





#####################################################################
# Handle the <install>...</install> tag

sub start_element_install {
	$_[0]->_push(
		bless {
			commands => [],
			tests    => [],
		}, 'PITA::XML::Install'
	);
}

sub end_element_install {
	my $self = shift;

	# Complete the install and add to the report
	my $install = $self->_pop->_init;
	$self->_context->add_install( $install );

	return 1;
}





#####################################################################
# Handle the <request>...</request> tag

sub start_element_request {
	my $self    = shift;
	my $request = bless { }, 'PITA::XML::Request';

	# Add the id if it has one
	my $attr = shift;
	if ( defined $attr->{id} ) {
		$request->{id} = $attr->{id};
	}

	$self->_push( $request );
}

sub end_element_request {
	my $self = shift;

	# Complete the Request and add to the Install
	$self->_context->{request} = $self->_pop->_init;

	return 1;
}





#####################################################################
# Handle the <file>...</file> tag

sub start_element_file {
	$_[0]->_push(
		bless { }, 'PITA::XML::File'
	);
}

sub end_element_file {
	my $self = shift;

	# Complete the Platform and add to the parent Install/Guest
	my $file = $self->_pop->_init;
	if ( _INSTANCE($self->_context, 'PITA::XML::Guest') ) {
		$self->_context->add_file( $file );
	} elsif ( _INSTANCE($self->_context, 'PITA::XML::Request') ) {
		$self->_context->{file} = $file;
	}

	return 1;
}





#####################################################################
# Handle the <platform>...</platform> tag

sub start_element_platform {
	$_[0]->_push(
		bless {
			env    => {},
			config => {},
		}, 'PITA::XML::Platform'
	);
}

sub end_element_platform {
	my $self = shift;

	# Complete the Platform and add to the parent Install/Guest
	my $platform = $self->_pop->_init;
	if ( _INSTANCE($self->_context, 'PITA::XML::Install') ) {
		$self->_context->{platform} = $platform;
	} elsif ( _INSTANCE($self->_context, 'PITA::XML::Guest') ) {
		$self->_context->add_platform( $platform );
	}

	return 1;
}





#####################################################################
# Handle the <command>...</command> tag

sub start_element_command {
	$_[0]->_push(
		bless {}, 'PITA::XML::Command'
	);
}

sub end_element_command {
	my $self = shift;

	# Complete the Command and add to the Install
	my $command = $self->_pop->_init;
	push @{ $self->_context->{commands} }, $command;

	return 1;
}





#####################################################################
# Handle the <test>...</test> tag

sub start_element_test {
	my $self = shift;
	my $hash = shift;

	# Create the test object
	my $test = bless {
		language => $hash->{language},
	}, 'PITA::XML::Test';
	if ( $hash->{name} ) {
		$test->{name} = $hash->{name};
	}

	$self->_push( $test );
}

sub end_element_test {
	my $self = shift;

	# Complete the Command and add to the Install
	my $test = $self->_pop->_init;
	push @{ $self->_context->{tests} }, $test;

	return 1;
}





#####################################################################
# Handle the <stdout>...</stdout> tag

# Start capturing the STDOUT content
sub start_element_stdout {
	$_[0]->{chars} = '';
	return 1;
}

# Save those chars to the element by reference, not plain strings
sub end_element_stdout {
	my $self = shift;

	# Add the $name to the context
	my $stdout = delete $self->{chars};
	$self->_context->{stdout} = \$stdout;

	return 1;
}





#####################################################################
# Handle the <stderr>...</stderr> tag

# Start capturing the STDERR content
sub start_element_stderr {
	$_[0]->{chars} = '';
	return 1;
}

# Save those chars to the element by reference, not plain strings
sub end_element_stderr {
	my $self = shift;

	# Add the $name to the context
	my $stderr = delete $self->{chars};
	$self->_context->{stderr} = \$stderr;

	return 1;
}





#####################################################################
# Handle the <env>...</env> tag

# Start capturing the $ENV{key} content
sub start_element_env {
	my $self = shift;
	my $hash = shift;
	$self->{chars} = '';
	$self->_push( $hash->{name} );
}

# Save those chars to the element by reference, not plain strings
sub end_element_env {
	my $self = shift;

	# Add the vey/value pair to the env propery
	my $name  = $self->_pop;
	my $value = delete $self->{chars};
	$self->_context->{env}->{$name} = $value;

	return 1;
}





#####################################################################
# Handle the <config>...</config> tag

# Start capturing the %Config::Config content
sub start_element_config {
	my $self = shift;
	my $hash = shift;
	$self->{chars} = '';
	$self->_push( $hash->{name} );
}

# Save those chars to the element by reference, not plain strings
sub end_element_config {
	my $self = shift;

	# Add the vey/value pair to the config propery
	my $name  = $self->_pop;
	my $value = delete $self->{chars};
	$self->_context->{config}->{$name} = $value;

	return 1;
}





#####################################################################
# Handle <null/> tags in a variety of things

sub start_element_null {
	my $self = shift;
	my $hash = shift;

	# A null tag indicates that the currently-accumulating character
	# buffer should be set to undef.
	if ( exists $self->{chars} ) {
		$self->{chars} = undef;
	}

	return 1;
}

sub end_element_null {
	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-XML>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 SEE ALSO

L<PITA::XML>, L<PITA::XML::SAXDriver>

The Perl Image-based Testing Architecture (L<http://ali.as/pita/>)

=head1 COPYRIGHT

Copyright 2005 - 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
