package Perl::SAX;

=pod

=head1 NAME

Perl::SAX - Generate SAX events for perl source code (incomplete)

=head1 DESCRIPTION

With the completion of L<PPI> and the potential creation of a viable
refactoring Perl editor, there has been renewed interest in parsing perl
source code and "Doing Stuff" with it.

It was felt (actually, it was demanded) that there should be some sort of
event mechanism that could go through a chunk of perl source code and emit
events that would be handled by a variety of methods.

Rather than invent my own, it was much easier to hijack SAX for this
purpose.

C<Perl::SAX> is the result of this need. Starting with a single object of any
type descended from L<PPI::Node>, C<Perl::SAX> will generate a stream of SAX
events.

For the sake of compatibility with SAX as a whole, and in the spirit of not
dictating the default behaviour based on any one use of this event stream,
the stream of events will be such that it can be passed to L<XML::SAX::Writer>
and a "PerlML" file will be spat out.

This provides the highest level of detail, and allows for a variety of
different potential uses, relating to both the actual and lexical content
inside of perl source code.

=head2 Perl::SAX is just a SAX Driver

Please note that C<Perl::SAX> is B<only> a SAX Driver. It cannot be used
as a SAX Filter or some other form of SAX Handler, and will die fatally if
you try, as soon as it recieves a C<start_document> event.

To restart Perl::SAX only B<creates> events, it cannot consume them.

=head2 Current State of Completion

This basic first working version is being uploaded to support the creation
of an L<Acme::Bleach> rip-off using PerlML.

=cut

use 5.005;
use strict;
use Carp           'croak';
use Params::Util   '_INSTANCE';
use PPI::Util      '_Document';
use XML::SAX::Base ();
eval "use prefork 'XML::SAX::Writer';";

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.08';
	@ISA     = 'XML::SAX::Base';
}

# While in development, use a version-specific namespace.
# In theory, this ensures documents are only truly valid with the
# version they were created with.
use constant XMLNS => 'http://ali.as/xml/schema/perlml/$VERSION';





#####################################################################
# Constructor and Accessors

=pod

=head1 METHODS

=head2 new [ Handler => $Handler | Output => $WriterConsumer ]

The C<new> constructor creates a new Perl SAX Driver instance.

If passed no arguments, it creates a new default L<XML::SAX::Writer> object,
which by default will write the resulting PerlML file to STDOUT.

If passed an C<Output =E<gt> $Consumer> argument, this value will be passed
along to the L<XML::SAX::Writer> constructor. Any value that is legal for
the Output parameter to L<XML::SAX::Writer> is also legal here.

If passed a C<Handler =E<gt> $Handler> argument, C<$Handler> will be used
as the SAX Handler directly. Any value provided via Output in this case will
be ignored.

Returns a new C<Perl::SAX> object, or C<undef> if you pass an illegal Output
value, and the L<XML::SAX::Writer> cannot be created.

=cut

sub new {
	my $class = shift;
	my %param = @_;

	# Create the empty object
	my $self = bless {
		NamespaceURI => '',
		Prefix       => '',
		Handler      => undef,
		}, $class;

	# Have we been passed a custom handler?
	if ( $param{Handler} ) {
		### It appears there is no way to test the validity of a SAX handler
		$self->{Handler} = $param{Handler};
	} else {
		# Default to an XML::Writer.
		# Have we been passed in Consumer for it?
		if ( $param{Output} ) {
			$self->{Output} = $param{Output};
		} else {
			my $Output = '';
			$self->{Output} = \$Output;
		}

		# Add the handler for the Output
		require XML::SAX::Writer;
		$self->{Handler} = XML::SAX::Writer->new(
			Output => $self->{Output},
			) or return undef;
	}

	# Generate NamespaceURI information?
	if ( $param{NamespaceURI} ) {
		if ( length $param{NamespaceURI} > 1 ) {
			# Custom namespace
			$self->{NamespaceURI} = $param{NamespaceURI};
		} else {
			# Default namespace
			$self->{NamespaceURI} = XMLNS;
		}
	}

	# Use a prefix?
	if ( $param{Prefix} ) {
		$self->{Prefix} = $param{Prefix};
	}

	$self;
}

sub NamespaceURI { $_[0]->{NamespaceURI} }
sub Prefix       { $_[0]->{Prefix}       }
sub Handler      { $_[0]->{Handler}      }
sub Output       { $_[0]->{Output}       }





#####################################################################
# Main Methods

# Prevent use as a SAX Filter.
# We only generate SAX events, we don't consume them.
sub start_document {
	my $class = ref $_[0] || $_[0];
	croak "$class can only be used as a SAX Driver";
}

sub parse {
	my $self     = shift;
	my $Document = _INSTANCE(shift, 'PPI::Document') or return undef;

	# Generate the SAX2 events
	$self->SUPER::start_document( {} );
	$self->_parse_document( $Document ) or return undef;
	$self->SUPER::end_document( {} );

	1;
}

sub _parse {
	my $self    = shift;
	my $Element = _INSTANCE(shift, 'PPI::Element') or return undef;

	# Split to the various generic handlers
	  $Element->isa('PPI::Token')     ? $self->_parse_token( $Element )
	: $Element->isa('PPI::Statement') ? $self->_parse_statement( $Element )
	: $Element->isa('PPI::Structure') ? $self->_parse_structure( $Element )
	: undef;
}

sub _parse_document {
	my $self     = shift;
	my $Document = _INSTANCE(shift, 'PPI::Document') or return undef;

	# Generate the SAX2 events
	my $Element = $self->_element( $Document ) or return undef;
	$self->start_element( $Element );
	foreach my $Child ( $Document->elements ) {
		$self->_parse( $Child ) or return undef;
	}
	$self->end_element( $Element );

	1;
}

sub _parse_token {
	my $self  = shift;
	my $Token = _INSTANCE(shift, 'PPI::Token') or return undef;

	# Support custom handlers
	my $method = $self->_tag_method( $Token );
	return $self->$method( $Token ) if $self->can($method);

	# Generate the SAX2 events
	my $Element = $self->_element( $Token ) or return undef;
	$self->start_element( $Element );
	$self->characters( {
		Data => $Token->content,
		} );
	$self->end_element( $Element );

	1;
}

sub _parse_statement {
	my $self      = shift;
	my $Statement = _INSTANCE(shift, 'PPI::Statement') or return undef;

	# Support custom handlers
	my $method = $self->_tag_method( $Statement );
	if ( $method ne '_parse_statement' and $self->can($method) ) {
		return $self->$method( $Statement );
	}

	# Generate the SAX2 events
	my $Element = $self->_element( $Statement ) or return undef;
	$self->start_element( $Element );
	foreach my $Child ( $Statement->elements ) {
		$self->_parse( $Child ) or return undef;
	}
	$self->end_element( $Element );

	1;
}

sub _parse_structure {
	my $self      = shift;
	my $Structure = _INSTANCE(shift, 'PPI::Structure') or return undef;

	# Support custom handlers
	my $method = $self->_tag_method( $Structure );
	if ( $self->can($method) and $method ne '_parse_structure' ) {
		return $self->$method( $Structure );
	}

	# Generate the SAX2 events
	my $Element = $self->_element( $Structure ) or return undef;
	$self->start_element( $Element );
	foreach my $Child ( $Structure->elements ) {
		$self->_parse( $Child ) or return undef;		
	}
	$self->end_element( $Element );

	1;
}





#####################################################################
# Support Methods

# Strip out the Attributes for the end element
sub end_element {
	delete $_[1]->{Attributes};
	shift->SUPER::end_element(@_);
}

# Auto-preparation of the text
sub characters {
	my $self = shift;
	(ref $_[0])
		? $self->SUPER::characters(shift)
		: $self->SUPER::characters( {
			Data => $self->_escape(shift),
			} );
}

sub _tag_method {
	my $tag = lc ref $_[1];
	$tag =~ s/::/_/g;
	'_parse_' . substr $tag, 4;
}

sub _element {
	my $self      = shift;
	my ($LocalName, $attr) = _INSTANCE($_[0], 'PPI::Element')
		? ($_[0]->_xml_name, $_[0]->_xml_attr)
		: ($_[0], (ref $_[1] eq 'HASH')
			? $_[1]
			: {} );

	# Localise some variables for speed
	my $NamespaceURI = $self->{NamespaceURI};
	my $Prefix       = $self->{Prefix}
		? "$self->{Prefix}:"
		: '';

	# Convert the attributes to the full version
	my %Attributes = ();
	foreach my $key ( keys %$attr ) {
		$Attributes{"{$NamespaceURI}$key"} = {
			Name         => $Prefix . $key,
			NamespaceURI => $NamespaceURI,
			Prefix       => $Prefix,
			LocalName    => $key,
			Value        => $attr->{$key},
		};
	}

	# Create the main element
	return {
		Name         => $Prefix . $LocalName,
		NamespaceURI => $NamespaceURI,
		Prefix       => $Prefix,
		LocalName    => $LocalName,
		Attributes   => \%Attributes,
	};
}

### Not sure if we escape here.
### Just pass through for now.
sub _escape { $_[1] }

1;

=pod

=head1 TO DO

Design and create the PerlML Schema

Make any changes needed to conform to it

Write a bunch of tests

=head1 SUPPORT

Because the development of the PerlML Schema (and thus this module) has not
been completed yet, please do not report bugs B<other than> those that
are installation-related.

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-SAX>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<PPI>, L<Acme::PerlML>

=head1 COPYRIGHT

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the Open Sourcing and release of this distribution.

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
