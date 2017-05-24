
package PRANG::Marshaller;
$PRANG::Marshaller::VERSION = '0.20';
use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;

use XML::LibXML 1.65;
use PRANG::Util qw(types_of);
use Carp;

BEGIN {
	class_type 'Moose::Meta::Class';
	class_type "Moose::Meta::Role";
	class_type "XML::LibXML::Element";
	class_type "XML::LibXML::Node";
	role_type "PRANG::Graph";
}

has 'class' =>
	isa => "Moose::Meta::Class|Moose::Meta::Role",
	is => "ro",
	required => 1,
	handles => [qw(marshall_in_element to_libxml)],
	trigger => sub {
	my $self = shift;
	my $class = shift;

	if ( !$class->can("marshall_in_element") && ! $class->does_role('PRANG::Graph') ) {

		$class = $class->name if ref $class;
		die "Can't marshall $class; didn't 'use PRANG::Graph' ?";
	}
	},
	;
	
has 'encoding' =>
    isa => 'Str',
    is => 'ro',
    default => 'UTF-8';

our %marshallers;  # could use MooseX::NaturalKey?

sub get {
    my $inv = shift;
    my ( $class ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );      
    
	if ( ref $inv ) {
		$inv = ref $inv;
	}
	$class->can("meta") or do {
		my $filename = $class;
		$filename =~ s{::}{/}g;
		$filename .= ".pm";
		if ( !$INC{$filename} ) {
			eval { require $filename };
		}
		$class->can("meta") or
			die "cannot marshall $class; no ->meta";
	};
	my $meta = $class->meta;
	if ($meta->does_role("PRANG::Graph")
		or
		$meta->meta->does_role("PRANG::Graph::Meta::Class")
		)
	{
	    
	    my $encoding = $class->can('encoding') ? $class->encoding : 'UTF-8';
		$marshallers{$class} ||= do {
			$inv->new( class => $class->meta, encoding => $encoding );
			}			
	}
	else {
		die "cannot marshall ".$meta->name
			."; not a PRANG Class/Node";
	}
}

sub parse {
    my $self = shift;
    my ( $xml, $filename, $fh, $lax ) = validated_list(
        \@_,
        xml => { isa => 'Str', optional => 1 },
        filename => { isa => 'Str', optional => 1 },
        fh => { isa => 'GlobRef', optional => 1 },
        lax => { isa => 'Bool', optional => 1, default => 0 },
    );

    my $parser = XML::LibXML->new;
    my $dom = (
        defined $xml ? $parser->parse_string($xml) :
            defined $filename ? $parser->parse_file($filename) :
            defined $fh ? $parser->parse_fh($fh) :
            croak("no input passed to parse")
    );

    return $self->from_dom(
        dom => $dom,
        lax => $lax
    );
}

sub from_dom {
    my $self = shift;

    my ( $dom, $lax ) = validated_list(
        \@_,
        dom => { isa => 'XML::LibXML::Document', },
        lax => { isa => 'Bool', optional => 1, default => 0 },
    );

	my $rootNode = $dom->documentElement;
	
	return $self->from_root_node(
	   root_node => $rootNode,
	   lax => $lax,
	);
}

sub from_root_node {
    my $self = shift;

    my ( $rootNode, $lax ) = validated_list(
        \@_,
        root_node => { isa => 'XML::LibXML::Node', },
        lax => { isa => 'Bool', optional => 1, default => 0 },
    );
    
	my $rootNodeNS = $rootNode->namespaceURI;

	my $xsi = {};
	if ( $self->class->isa("Moose::Meta::Role") ) {
		my @possible = types_of($self->class);
		my $found;
		my $root_localname = $rootNode->localname;
		my @expected;
		for my $class (@possible) {
			if ($root_localname eq
				$class->name->root_element
				)
			{

				# yeah, this is lazy ;-)
				$self = (ref $self)->get($class->name);
				$found = 1;
				last;
			}
			else {
				push @expected, $class->name->root_element;
			}
		}
		if ( !$found ) {
			die "No type of ".$self->class->name
				." that expects '$root_localname' as a root element (expected: @expected)";
		}
	}
	my $expected_ns = $self->class->name->xmlns;
	if ( $rootNodeNS and $expected_ns ) {
		if ( $rootNodeNS ne $expected_ns ) {
			die
"Namespace mismatch: expected '$expected_ns', found '$rootNodeNS'";
		}
	}
	if (!defined($rootNode->prefix)
		and
		!defined($rootNode->getAttribute("xmlns"))
		)
	{

		# namespace free;
		$xsi->{""}="";
	}

	my $context = PRANG::Graph::Context->new(
		base => $self,
		xpath => "",
		xsi => $xsi,
		prefix => "",
	);
	
	my $rv = $self->class->marshall_in_element(
		$rootNode,
		$context,
		$lax,
	);
	$rv;
}

sub xml_version { "1.0" }

# nothing to see here ... move along please ...
our $zok;
our %zok_seen;
our @zok_themes = (
	qw( tmnt octothorpe quantum pokemon hhgg pasta
		phonetic sins punctuation discworld lotr
		loremipsum batman tld garbage python pooh
		norse_mythology )
);
our $zok_theme;

our $gen_prefix;

sub generate_prefix {
    my $self = shift;
    my ( $xmlns ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );    
    
	if ( $zok or eval { require Acme::MetaSyntactic; 1 } ) {
		my $name;
		do {
			$zok ||= do {
				%zok_seen=();
				if ( defined $zok_theme ) {
					$zok_theme++;
					if ( $zok_theme > $#zok_themes ) {
						$zok_theme = 0;
					}
				}
				else {
					$zok_theme = int(time() / 86400)
						% scalar(@zok_themes);
				}
				Acme::MetaSyntactic->new(
					$zok_themes[$zok_theme],
				);
			};
			do {
				$name = $zok->name;
				if ($zok_seen{$name}++) {
					undef($zok);
					undef($name);
					goto next_theme;
				}
				} while (
				length($name) > 10
				or
				$name !~ m{^[A-Za-z]\w+$}
				);
		next_theme:
			}
			until ($name);
		return $name;
	}
	else {

		# revert to a more boring prefix :)
		$gen_prefix ||= "a";
		$gen_prefix++;
	}
}

sub to_xml_doc {
    my $self = shift;
    my ( $item ) = pos_validated_list(
        \@_,
        { isa => 'PRANG::Graph' },
    );    
    
	my $xmlns = $item->xmlns;
	my $prefix = "";
	if ( $item->can("preferred_prefix") ) {
		$prefix = $item->preferred_prefix;
	}
	my $xsi = { $prefix => ($xmlns||"") };

	# whoops, this is non-reentrant
	%zok_seen=();
	undef($gen_prefix);
	my $doc = XML::LibXML::Document->new(
		$self->xml_version, $self->encoding,
	);
	my $root = $doc->createElement(
		($prefix ? "$prefix:" : "" ) .$item->root_element,
	);
	if ($xmlns) {
		$root->setAttribute(
			"xmlns".($prefix?":$prefix":""),
			$xmlns,
		);
	}
	$doc->setDocumentElement($root);
	my $ctx = PRANG::Graph::Context->new(
		xpath => "/".$root->nodeName,
		base => $self,
		prefix => $prefix,
		xsi => $xsi,
	);
	$item->meta->to_libxml( $item, $root, $ctx );
	$doc;
}

sub to_xml {
    my $self = shift;
    my ( $item, $format ) = pos_validated_list(
        \@_,
        { isa => 'PRANG::Graph' },
        { isa => 'Int', default => 0 },
    );    
    
	my $document = $self->to_xml_doc($item);
	$document->toString($format);
}

1;

__END__

=head1 NAME

PRANG::Marshaller - entry point for PRANG XML marshalling machinery

=head1 SYNOPSIS

 my $marshaller = PRANG::Marshaller->get($class_or_role);

 my $object = $marshaller->parse($xml);

 my $xml = $marshaller->to_xml($object);

=head1 DESCRIPTION

The B<PRANG::Marshaller> currently serves two major functions;

=over

=item 1.

A place-holder for role-based marshalling (ie, marshalling documents
with multiple root element types)

=item 2.

A place for document-scoped information on emitting to be held (ie,
mapping XML namespace prefixes to URIs and generating namespace
prefixes).

=back

This class is a bit of a stop-gap measure; it started out as the only
place where any XML marshalling happened, and gradually parts have
been moved into metaclass methods, in packages such as
L<PRANG::Graph::Meta::Class>, L<PRANG::Graph::Meta::Element> and
L<PRANG::Graph::Node> implementations.

=head1 SEE ALSO

L<PRANG>, L<PRANG::Graph::Meta::Class>,
L<PRANG::Graph::Meta::Element>, L<PRANG::Graph::Node>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

