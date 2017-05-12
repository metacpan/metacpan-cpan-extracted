package RDF::vCard::Exporter;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);

use MIME::Base64 qw[];
use RDF::vCard::Entity;
use RDF::vCard::Line;
use RDF::TrineX::Functions
	-shortcuts,
	iri => { -as => 'rdf_resource' };
use Scalar::Util qw[blessed];
use URI;

# kinda constants
sub V    { return 'http://www.w3.org/2006/vcard/ns#' . shift; }
sub VX   { return 'http://buzzword.org.uk/rdf/vcardx#' . shift; }
sub RDF  { return 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' . shift; }
sub XSD  { return 'http://www.w3.org/2001/XMLSchema#' . shift; }

sub flatten_node
{
	my $node = shift;
	return $node->value if $node->is_resource || $node->is_literal;
	return $node->as_ntriples;
}

use namespace::clean;

our $VERSION = '0.012';
our $PRODID  = sprintf("+//IDN cpan.org//NONSGML %s v %s//EN", __PACKAGE__, $VERSION);

our %dispatch = (
	V('adr')             => \&_prop_export_adr,
	V('n')               => \&_prop_export_n,
	V('geo')             => \&_prop_export_geo,
	V('org')             => \&_prop_export_org,
	V('agent')           => \&_prop_export_agent,
	V('tel')             => \&_prop_export_typed,
	V('email')           => \&_prop_export_typed,
	V('label')           => \&_prop_export_typed,
	VX('impp')           => \&_prop_export_typed,
	V('fax')             => \&_prop_export_shortcut,
	V('homeAdr')         => \&_prop_export_shortcut,
	V('homeTel')         => \&_prop_export_shortcut,
	V('mobileEmail')     => \&_prop_export_shortcut,
	V('mobileTel')       => \&_prop_export_shortcut,
	V('personalEmail')   => \&_prop_export_shortcut,
	V('unlabeledAdr')    => \&_prop_export_shortcut,
	V('unlabeledEmail')  => \&_prop_export_shortcut,
	V('unlabeledTel')    => \&_prop_export_shortcut,
	V('workAdr')         => \&_prop_export_shortcut,
	V('workEmail')       => \&_prop_export_shortcut,
	V('workTel')         => \&_prop_export_shortcut,
	V('photo')           => \&_prop_export_binary,
	V('sound')           => \&_prop_export_binary,
	V('logo')            => \&_prop_export_binary,
	V('key')             => \&_prop_export_binary,
	);

sub new
{
	my ($class, %options) = @_;
	bless { %options }, $class;
}

sub is_v4
{
	my ($self) = @_;
	return ($self->{vcard_version} =~ /4/) ? 4 : 0;
}

sub is_v3
{
	my ($self) = @_;
	return $self->is_v4 ? 0 : 3;
}

sub export_cards
{
	my ($self, $model, %options) = @_;
	$model = rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my @subjects =  $model->subjects(rdf_resource(RDF('type')), rdf_resource(V('VCard')));
	push @subjects, $model->subjects(rdf_resource(V('fn')), undef);	
	my %subjects = map { flatten_node($_) => $_ } @subjects;
	
	my @cards;
	foreach my $s (values %subjects)
	{
		push @cards, $self->export_card($model, $s, %options);
	}
	
	if ($options{sort})
	{
		return sort { $a->entity_order cmp $b->entity_order } @cards;
	}
	
	return @cards;
}

sub export_card
{
	my ($self, $model, $subject, %options) = @_;
	$model = RDF::TrineShortcuts::rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my $card = RDF::vCard->new_entity( profile=>'VCARD' );
	
	my %categories;
	my $triples = $model->get_statements($subject, undef, undef);
	while (my $triple = $triples->next)
	{
		next
			unless (substr($triple->predicate->uri, 0, length(&V)) eq &V or
					  substr($triple->predicate->uri, 0, length(&VX)) eq &VX);

		if (defined $dispatch{$triple->predicate->uri}
		and ref($dispatch{$triple->predicate->uri}) eq 'CODE')
		{
			my $code = $dispatch{$triple->predicate->uri};
			$card->add($code->($self, $model, $triple));
		}
		elsif ($triple->predicate->uri eq V('category')
		or     $triple->predicate->uri eq VX('category'))
		{
			my $c = $self->_prop_extract_category($model, $triple);
			$categories{$c}++;
		}
		elsif (! $triple->object->is_blank)
		{
			$card->add($self->_prop_export_simple($model, $triple));
		}
	}
	
	if (keys %categories)
	{
		$card->add(
			RDF::vCard::Line->new(
				property        => 'categories',
				value           => [[ sort keys %categories ]],
				)
			);
	}
	
	$card->add(
		RDF::vCard::Line->new(
			property        => 'version',
			value           => $self->is_v4 ? '4.0' : '3.0',
			)
		);
		
	$card->add(
		RDF::vCard::Line->new(
			property        => 'prodid',
			value           => (defined $options{prodid} ? $options{prodid} : $PRODID),
			)
		) unless exists $options{prodid} && !defined $options{prodid};

	$card->add(
		RDF::vCard::Line->new(
			property        => 'source',
			value           => $options{source},
			type_parameters => {value=>'URI'},
			)
		) if defined $options{source};

	return $card;
}

{
	my %dtmap = (
		XSD('anyURI')        => 'URI',
		XSD('string')        => 'TEXT',
		XSD('integer')       => 'INTEGER',
		XSD('date')          => 'DATE',
		XSD('dateTime')      => 'DATE-TIME',
		XSD('duration')      => 'DURATION',
		'urn:iso:std:iso:8601#timeInterval' => 'PERIOD',
		XSD('decimal')       => 'FLOAT',
		# BOOLEAN ?
		);
	
	sub _prop_export_simple
	{
		my ($self, $model, $triple) = @_;
		
		my $prop = 'x-data';
		if ($triple->predicate->uri =~ m/([^\#\/]+)$/)
		{
			$prop = $1;
		}
		
		my $val    = flatten_node($triple->object);
		my $params = undef;
		
		if ($triple->object->is_literal
		and $triple->object->has_datatype
		and defined $dtmap{ $triple->object->literal_datatype })
		{
			$params = { value => $dtmap{ $triple->object->literal_datatype } };
		}

		elsif ($triple->object->is_literal
		and $triple->object->has_language)
		{
			$params = { value=>'TEXT', language=>$triple->object->literal_value_language };
		}

		elsif ($triple->object->is_resource)
		{
			$params = { value=>'URI' };
		}

		return RDF::vCard::Line->new(
			property        => $prop,
			value           => $val,
			type_parameters => $params,
			);
	}
}

sub _prop_export_adr
{
	my ($self, $model, $triple) = @_;
	
	my $adr = [];
	foreach my $part (qw(post-office-box extended-address street-address locality
		region postal-code country-name))
	{
		my @objects = $model->objects($triple->object, rdf_resource(V($part)));
		push @$adr, [ map { flatten_node($_) } @objects ];
	}

	my $params = {};
	my $types  = {};
	unless ($triple->object->is_literal)
	{
		my @types  = $model->objects($triple->object, rdf_resource(RDF('type')));
		push @types, $model->objects($triple->object, rdf_resource(VX('usage')));
		foreach my $type (@types)
		{
			if ($type->is_resource and $type->uri =~ m/([^\#\/]+)$/)
			{
				$types->{ uc $1 } = 1;
			}
			elsif ($type->is_literal)
			{
				$types->{ uc $type->literal_value } = 1;
			}
		}
	}
	delete $types->{TEL};
	delete $types->{EMAIL};
	delete $types->{IMPP};
	delete $types->{ADDRESS};
	delete $types->{LABEL};
	
	my @geos;
	my $iter = $model->get_statements($triple->object, rdf_resource(VX('geo')), undef);
	while (my $st = $iter->next)
	{
		my $gline = $self->_prop_export_geo($model, $st);
		push @geos, $gline->_unescape_value($gline->value_to_string);
	}
	if (@geos)
	{
		$params->{geo} = \@geos;
	}
	
	if (%$types and $self->is_v4)
	{
		$params->{type} = [sort grep { !/^pref$/i } keys %$types];
		$params->{pref} = 1 if $types->{PREF};
	}
	elsif (%$types)
	{
		$params->{type} = [sort keys %$types];
	}
	$params = undef unless %$params;

	return RDF::vCard::Line->new(
		property => 'adr',
		value    => $adr,
		type_parameters => $params,
		);
}

sub _prop_export_n
{
	my ($self, $model, $triple) = @_;
	
	my $n = [];
	foreach my $part (qw(family-name given-name additional-name honorific-prefix honorific-suffix))
	{
		my @objects = $model->objects($triple->object, rdf_resource(V($part)));
		push @$n, [ map { flatten_node($_) } @objects ];
	}
	
	return RDF::vCard::Line->new(
		property => 'n',
		value    => $n,
		);
}

sub _prop_export_agent
{
	my ($self, $model, $triple) = @_;
	
	if ($triple->object->is_literal)
	{
		return RDF::vCard::Line->new(
			property => 'agent',
			value    => flatten_node($triple->object),
			type_parameters => { value=>'TEXT' },
			);
	}
	
	my $agent = $self->export_card($model, $triple->object);
	
	return RDF::vCard::Line->new(
		property => 'agent',
		value    => $agent->to_string,
		type_parameters => { value=>'VCARD' },
		);
}

sub _prop_export_org
{
	my ($self, $model, $triple) = @_;
	
	# Note: W3C Member Submission is inconsistent with regards to organiSation/organiZation.
	my @objects = $model->objects_for_predicate_list($triple->object, rdf_resource(V('organization-name')), rdf_resource(V('organisation-name')));
	my @values  = map { flatten_node($_) } grep {$_->is_literal} @objects;
	my $org     = [ ($values[0] || '') ];

	@objects = $model->objects_for_predicate_list($triple->object, rdf_resource(V('organization-unit')), rdf_resource(V('organisation-unit')));
	push @$org, map { flatten_node($_) } grep {$_->is_literal} @objects;

	return RDF::vCard::Line->new(
		property => 'org',
		value    => $org,
		);
}

sub _prop_export_geo
{
	my ($self, $model, $triple) = @_;
	
	my $g = [];
	foreach my $part (qw(latitude longitude))
	{
		my @objects = $model->objects($triple->object, rdf_resource(V($part)));
		my @values  = map { flatten_node($_) } grep {$_->is_literal} @objects;
		push @$g, ($values[0] || '');
	}
	
	if ($self->is_v4)
	{
		return RDF::vCard::Line->new(
			property => 'geo',
			value    => sprintf('geo:%f,%f', @$g),
			type_parameters => { value=>'URI' },
			);
	}
	else
	{
		return RDF::vCard::Line->new(
			property => 'geo',
			value    => $g,
			type_parameters => { value=>'TEXT' },
			);
	}
}

# tel, email, label and impp may be typed
sub _prop_export_typed
{
	my ($self, $model, $triple) = @_;
	
	my $value_node = $triple->object;
	unless ($value_node->is_literal)
	{
		my @objects = $model->objects($value_node, rdf_resource(RDF('value')));
		foreach my $o (@objects)
		{
			unless ($o->is_blank)
			{
				$value_node = $o;
				last;
			}
		}
	}
	my $value = flatten_node($value_node);

	my $prop = 'x-data';
	if ($triple->predicate->uri =~ m/([^\#\/]+)$/)
	{
		$prop = lc $1;
	}
	
	my $types  = {};
	my $params = {};
	if ($prop eq 'email' and $value =~ /^mailto:(.+)$/i)
	{
		$value = $1;
		$types->{INTERNET} = 1;
	}
	elsif ($prop eq 'tel' and $value =~ /^(tel|fax|modem):(.+)$/i)
	{
		if ($self->is_v4) #v4 telephone numbers are URIs
		{
			$params = { value=>'URI' };
		}
		else #v3 telephone numbers are text (well VALUE=PHONE-NUMBER technically)
		{
			$value = $2;
		}
		$types->{FAX}   = 1 if lc $1 eq 'fax';
		$types->{MODEM} = 1 if lc $1 eq 'modem';
	}
	elsif ($value_node->is_resource)
	{
		$params = { value=>'URI' };
	}
	
	unless ($triple->object->is_literal)
	{
		my @types  = $model->objects($triple->object, rdf_resource(RDF('type')));
		push @types, $model->objects($triple->object, rdf_resource(VX('usage')));
		foreach my $type (@types)
		{
			if ($type->is_resource and $type->uri =~ m/([^\#\/]+)$/)
			{
				$types->{ uc $1 } = 1;
			}
			elsif ($type->is_literal)
			{
				$types->{ uc $type->literal_value } = 1;
			}
		}
	}
	
	delete $types->{TEL};
	delete $types->{EMAIL};
	delete $types->{IMPP};
	delete $types->{ADDRESS};
	delete $types->{LABEL};
	
	if (%$types and $self->is_v4)
	{
		$params->{type} = [sort grep { !/^pref$/i } keys %$types];
		$params->{pref} = 1 if $types->{PREF};
	}
	elsif (%$types)
	{
		$params->{type} = [sort keys %$types];
	}
	$params = undef unless %$params;

	if ($prop eq 'tel')
	{
		$params->{'value'} ||= 'PHONE-NUMBER';
		
		if ($self->is_v4 and $params->{'value'} ne 'URI' and $value =~ /^\+[0-9\s\-]+$/)
		{
			$value =~ s/\s/-/g;
			$value = "tel:${value}";
			$params->{'value'} = 'URI';
		}
	}

	return RDF::vCard::Line->new(
		property        => $prop,
		value           => $value,
		type_parameters => $params,
		);
}

sub _prop_export_shortcut
{
	my ($self, $model, $triple) = @_;
	
	my $shortcuts = {
		V('fax')             => [V('tel')   => ['FAX']],
		V('homeAdr')         => [V('adr')   => ['HOME']],
		V('homeTel')         => [V('tel')   => ['HOME']],
		V('mobileEmail')     => [V('email') => undef], # EMAIL;TYPE=CELL not allowed by RFC 2426
		V('mobileTel')       => [V('tel')   => ['CELL']],
		V('personalEmail')   => [V('email') => undef], # RFC 2426 doesn't define TYPE=PERSONAL
		V('unlabeledAdr')    => [V('adr')   => undef],
		V('unlabeledEmail')  => [V('email') => undef],
		V('unlabeledTel')    => [V('tel')   => undef],
		V('workAdr')         => [V('adr')   => ['WORK']],
		V('workEmail')       => [V('email') => undef], # EMAIL;TYPE=WORK not allowed by RFC 2426
		V('workTel')         => [V('tel')   => ['WORK']],
		};
	
	if (exists $shortcuts->{$triple->predicate->uri})
	{
		my ($property_uri, $types) = @{ $shortcuts->{$triple->predicate->uri} };
		my $line;

		if (defined $dispatch{$property_uri}
		and ref($dispatch{$property_uri}) eq 'CODE')
		{
			my $code = $dispatch{$property_uri};
			$line    = $code->($self, $model, $triple);
		}
		elsif (! $triple->object->is_blank)
		{
			$line = $self->_prop_export_simple($model, $triple);
		}

		if ($line)
		{
			push @{ $line->type_parameters->{type} }, @$types;
			return $line;
		}
	}
}

sub _prop_export_binary
{
	my ($self, $model, $triple) = @_;
	my $line = $self->_prop_export_simple($model, $triple);
	
	if ($self->is_v3 and $line->value->[0] =~ /^data:\S+$/)
	{
		my $data_uri = URI->new( $line->value->[0] );
		my $data     = $data_uri->data;
		my $medium   = $data_uri->media_type;
		
		$line->value->[0] = MIME::Base64::encode_base64($data, '');
		$line->type_parameters->{value}    = 'BINARY';
		$line->type_parameters->{encoding} = 'B';
		$line->type_parameters->{type} = [ uc($1) ]
			if $medium =~ m'^image/([a-z0-9\_\-\+]+)'i;
		$line->type_parameters->{fmtype} = $medium
			if $medium =~ m'.+/.+';
	}
	
	return $line;
}

sub _prop_extract_category
{
	my ($self, $model, $triple) = @_;
	
	if ($triple->object->is_literal)
	{
		return uc $triple->object->literal_value;
	}

	my @labels = grep
		{ $_->is_literal }
		$model->objects_for_predicate_list(
			$triple->object,
			rdf_resource('http://www.w3.org/2004/02/skos/core#prefLabel'),
			rdf_resource('http://www.holygoat.co.uk/owl/redwood/0.1/tags/name'),
			rdf_resource('http://www.w3.org/2000/01/rdf-schema#label'),
			rdf_resource('http://www.w3.org/2004/02/skos/core#altLabel'),
			rdf_resource('http://www.w3.org/2004/02/skos/core#notation'),
			rdf_resource(RDF('value')),
			);
	
	if (@labels)
	{
		return uc $labels[0]->literal_value;
	}
	elsif ($triple->object->is_resource)
	{
		return $triple->object->uri;
	}
}


1;

__END__

=head1 NAME

RDF::vCard::Exporter - export RDF data to vCard format

=head1 SYNOPSIS

 use RDF::vCard;
 
 my $input    = "http://example.com/contact-data.rdf";
 my $exporter = RDF::vCard::Exporter->new(vcard_version => 3);
 
 print $_ foreach $exporter->export_cards($input);

=head1 DESCRIPTION

This module reads RDF and writes vCards.

=head2 Constructor

=over

=item * C<< new(%options) >>

Returns a new RDF::vCard::Exporter object.

Options:

=over

=item * B<vcard_version> - '3' or '4'. This module will happily use
vCard 3.0 constructs in vCard 4.0 and vice versa. But in certain places
it can lean one way or the other. This option allows you to influence
that.

=back

=back

=head2 Methods

=over

=item * C<< export_cards($input, %options) >>

Returns a list of vCards found in the input, in no particular order.

The input may be a URI, file name, L<RDF::Trine::Model> or anything else
that can be handled by the C<rdf_parse> method of L<RDF::TrineShortcuts>.

Supported options include B<sort> which, if set to true, causes the
output to be sorted by name (as well as is possible); B<source> which
allows you to provide the URL where the cards were sourced from; and
B<prodid> which allows you to set the product ID used in the output.

(A prodid must be in FPI format to be valid, though the module doesn't
check this. undef is allowed. By default, RDF::vCard:Exporter uses
its own prodid, and unless you have a good reason to change this, you
should probably let it.)

e.g.

  my @cards = $exporter->export_cards(
    $some_data,
    sort   => 1,
    source => 'http://bigcorp.example.com/data.rdf',
    prodid => '+//IDN example.net//NONSGML MyScript v 0.1//EN',
    );

Each item in the list returned is an L<RDF::vCard::Entity>, though
that class overloads stringification, so you can just treat each item
as a string mostly.
						
=item * C<< export_card($input, $subject, %options) >>

As per C<export_cards> but exports just a single card.

The subject provided must be an RDF::Trine::Node::Blank or
RDF::Trine::Node::Resource of type v:VCard.

=item * C<< is_v3 >>

Returns true if this exporter is in vCard 3.0 mode.

=item * C<< is_v4 >>

Returns true if this exporter is in vCard 4.0 mode.

=back

=head2 RDF Input

Input is expected to use the newer of the 2010 revision of the W3C's
vCard vocabulary L<http://www.w3.org/Submission/vcard-rdf/>. (Note that
even though this was revised in 2010, the term URIs include "2006" in
them.)

Some extensions from the namespace L<http://buzzword.org.uk/rdf/vcardx#>
are also supported. (Namely: vx:usage, vx:kind, vx:gender, vx:sex,
vx:dday, vx:anniversary, vx:lang, vx:caladruri, vx:caluri, vx:fburl,
vx:impp, vx:source.)

The module author has made the decision not to support FOAF and
other RDF vocabularies that may be used to model contact information
for people and organisations, as they do not necessarily map cleanly
onto vCard. People hoping to map non-vCard RDF to vCard using
this module may have some luck pre-processing their RDF using a
rules-based reasoner.

=head2 vCard Output

The output of this module mostly aims at vCard 3.0 (RFC 2426) compliance.
In the face of weird input data though, (e.g. an FN property that is a
URI instead of a literal) it can pretty easily descend into exporting
junk, non-compliant vCards.

Many vCard 4.0 properties, such as the IMPP and KIND, are also supported.

The B<vcard_version> constructor option allows you to influence how some
properties like GEO and TEL (which differ between 3.0 and 4.0) are output.

=head1 SEE ALSO

L<RDF::vCard>, L<HTML::Microformats>, L<RDF::TrineShortcuts>.

L<http://www.w3.org/Submission/vcard-rdf/>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

