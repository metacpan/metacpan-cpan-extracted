package RDF::vCard::Entity::WithXmlSupport;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use constant NS => 'urn:ietf:params:xml:ns:vcard-4.0';

use Scalar::Util qw[blessed];
use XML::LibXML;

use base qw'RDF::vCard::Entity';
use namespace::clean;

our $VERSION = '0.012';

sub promote
{
	my ($class, $self) = @_;
	die "Cannot promote non-RDF::vCard::Entity object!\n"
		unless blessed($self) && $self->isa('RDF::vCard::Entity');
	warn ("RDF::vCard::XML::Entity may not work property when used with %s input.", ref($self))
		unless ref($self) eq 'RDF::vCard::Entity'
		    || ref($self) eq 'RDF::vCard::XML::Entity';
	return bless $self, $class;
}

sub to_xml
{
	my ($self) = @_;	
	my $document = XML::LibXML->new->parse_string(sprintf('<vcards xmlns="%s" />', NS));
	$self->add_to_document($document);
	return $document->toString;
}

sub add_to_document
{
	my ($self, $document) = @_;
	my $root   = $document->documentElement->addNewChild(NS, 'vcard');
	my @sorted = sort
		{ $a->property_order cmp $b->property_order }
		@{ $self->{lines} };
	foreach my $l (@sorted)
	{
		next if $l->property =~ /^(version|prodid)$/i;
		$self->_add_line_to_node($l, $root);
	}
	return $root;
}

sub _add_line_to_node
{
	my ($self, $line, $node) = @_;
	my $prop_node = $node->addNewChild(NS, lc $line->property);
	
	my $method = sprintf('_add_value_to_node_%s', lc $line->property);
	$method = '_add_value_to_node_GENERIC' unless $self->can($method);
	$self->$method($line, $prop_node);
	return $prop_node;
}

sub _add_value_to_node_GENERIC
{
	my ($self, $line, $node) = @_;
	
	my $type = lc $line->type_parameters->{value} ||  'text';
	my $val_node = $node->addNewChild(NS, $type);
	$val_node->appendText($line->_unescape_value($line->value_to_string));
	
	my %params = %{ $line->type_parameters };
	delete $params{value};
	if (%params)
	{
		my $params_node = $node->addNewChild(NS, 'parameters');
		while (my ($p,$v) = each %params)
		{
			next unless length $p && defined $v;
			
			if (ref $v eq 'ARRAY')
			{
				foreach my $v2 (@$v)
				{
					$params_node->addNewChild(NS, lc $p)->appendText($v2||'');
				}
			}
			else
			{
				$params_node->addNewChild(NS, lc $p)->appendText($v||'');
			}
		}
	}
	
	return $val_node;
}

sub _add_value_to_node_n
{
	my ($self, $line, $node) = @_;
	
	my @child_names = qw(surname given additional prefix suffix);
	my @components  = @{ $line->nvalue };
	for (my $i = 0; defined $child_names[$i]; $i++)
	{
		my $component_node = $node->addNewChild(NS, $child_names[$i]);
		
		foreach my $value (@{ $components[$i] })
		{
			$component_node->addNewChild(NS, 'text')->appendText($value);
		}
	}
	
	return $node->childNodes;
}

sub _add_value_to_node_adr
{
	my ($self, $line, $node) = @_;
	
	my @child_names = qw(pobox ext street locality region code country);
	my @components  = @{ $line->nvalue };
	for (my $i = 0; defined $child_names[$i]; $i++)
	{
		my $component_node = $node->addNewChild(NS, $child_names[$i]);
		
		foreach my $value (@{ $components[$i] })
		{
			$component_node->addNewChild(NS, 'text')->appendText($value);
		}
	}
	
	return $node->childNodes;
}

1;


__END__

=head1 NAME

RDF::vCard::Entity::WithXmlSupport - subclass of RDF::vCard::Entity

=head1 DESCRIPTION

Subclass of L<RDF::vCard::Entity> with XML output support.

Requires L<XML::LibXML>.

=head2 Constructor

=over

=item * C<< new(%options) >>

As per L<RDF::vCard::Entity>.

=item * C<< promote($entity) >>

Clones an existing L<RDF::vCard::Entity>, but adds XML support.

=back

=head2 Methods

As per L<RDF::vCard::Entity>, but also:

=over

=item * C<< to_xml() >>

Formats the object according to the vCard XML Internet Draft.

=item * C<< add_to_document($document) >>

Given an L<XML::LibXML::Document> object, adds the vCard data to the document
as a child of the root element.

=back

=head1 SEE ALSO

L<RDF::vCard>.

L<http://tools.ietf.org/id/draft-ietf-vcarddav-vcardxml-06.txt>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

