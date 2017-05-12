package RDF::vCard::Line;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);

use Encode;
use MIME::Base64;
use RDF::Trine::Namespace qw[xsd];
use RDF::TrineX::Functions
	-shortcuts,
	statement => { -as => 'rdf_statement' },
	literal   => { -as => 'rdf_literal' },
	iri       => { -as => 'rdf_resource' };
use URI::data;

sub V    { return 'http://www.w3.org/2006/vcard/ns#' . shift; }
sub VX   { return 'http://buzzword.org.uk/rdf/vcardx#' . shift; }
sub RDF  { return 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' . shift; }
sub XSD  { return 'http://www.w3.org/2001/XMLSchema#' . shift; }

use namespace::clean;

use overload '""' => \&to_string;
our $VERSION = '0.012';

sub new
{
	my ($class, %options) = @_;
	die "Need to provide a property name\n"
		unless defined $options{property};
	$options{value} = [$options{value}]
		unless ref $options{value} eq 'ARRAY';
	$options{type_parameters} ||= [];
	bless { %options }, $class;
}

sub property
{
	my ($self) = @_;
	return $self->{property};
}

sub value
{
	my ($self) = @_;
	return $self->{value};
}

sub nvalue
{
	my ($self) = @_;
	my $value = $self->value;
	my @nvalue;
	foreach my $v (@$value)
	{
		push @nvalue, (ref($v) eq 'ARRAY' ? $v : [$v]);
	}
	return \@nvalue;
}

sub type_parameters
{
	my ($self) = @_;
	$self->{type_parameters} = {} unless ref $self->{type_parameters} eq 'HASH';
	return $self->{type_parameters};
}

sub property_order
{
	my ($self) = @_;
	my $p = lc $self->property;
	return 0 if $p eq 'version';
	return 1 if $p eq 'prodid';
	return 2 if $p eq 'source';
	return 3 if $p eq 'kind';
	return 4 if $p eq 'fn';
	return 5 if $p eq 'n';
	return 6 if $p eq 'org';
	return $p;
}

sub to_string
{
	my ($self) = @_;
	
	my $str = uc $self->property;
	if (keys %{ $self->type_parameters })
	{
		foreach my $parameter (sort keys %{ $self->type_parameters })
		{
			my $values = $self->type_parameters->{$parameter};
			$values = [$values]
				unless ref $values eq 'ARRAY';
			my $values_string = join ",", map { $self->_escape_value($_, is_tp=>1) } @$values;
			$str .= sprintf(";%s=%s", uc $parameter, $values_string);
		}
	}
	$str .= ":";
	$str .= $self->value_to_string;
	
	if (length $str > 75)
	{
		my $new = '';
		while (length $str > 64)
		{
			$new .= substr($str, 0, 64) . "\r\n ";
			$str  = substr($str, 64);
		}
		$new .= $str;
		$str  = $new;
	}
	
	return $str;
}

sub value_to_string
{
	my ($self) = @_;	
	my $str = join ";",
		map
		{ join ",", map { $self->_escape_value($_) } @{$_}; }
		@{ $self->nvalue };
	$str =~ s/;+$//;
	return $str;
}

sub _escape_value
{
	my ($self, $value, %options) = @_;
	
	if ($options{is_tp} and $value =~ /[;:,"]/)
	{
		$value =~ s/\\/\\\\/g;
		$value =~ s/\"/\\\"/g;
		return sprintf('"%s"', $value);
	}
	
	$value =~ s/\\/\\\\/g;
	
	$value =~ s/\r//g;
	$value =~ s/\n/\\n/g;
	$value =~ s/;/\\;/g;
	$value =~ s/,/\\,/g;
	
	return $value;
}

sub _unescape_value
{
	my ($self, $value, %options) = @_;
	
	$value =~ s/\\r//gi;
	$value =~ s/\\n/\n/gi;
	$value =~ s/\\;/;/g;
	$value =~ s/\\,/,/g;
	
	$value =~ s/\\\\/\\/g;
	
	return $value;
}

# RDF Export Stuff...

sub add_to_model
{
	my ($self, $model, $card_node) = @_;
	
	my $special_func = sprintf('_add_to_model_%s', uc $self->property);
	if ($self->can($special_func))
	{
		$self->$special_func($model, $card_node);
	}
	elsif ($self->property_node)
	{
		$model->add_statement(rdf_statement(
			$card_node,
			$self->property_node,
			$self->value_node,
			));
	}
	return $self;
}

sub value_node
{
	my ($self) = @_;

	return rdf_literal($self->value_to_string, undef, $xsd->date)
		if (defined $self->type_parameters and uc $self->type_parameters->{VALUE} eq 'DATE');

	return rdf_literal($self->value_to_string, undef, $xsd->dateTime)
		if (defined $self->type_parameters and uc $self->type_parameters->{VALUE} eq 'DATE-TIME');

	return rdf_resource($self->value_to_string)
		if (defined $self->type_parameters and uc $self->type_parameters->{VALUE} eq 'URI');

	if (defined $self->type_parameters
	and uc $self->type_parameters->{VALUE} eq 'BINARY'
	and uc $self->type_parameters->{ENCODING} eq 'B')
	{
		my $uri = URI->new('data:');
		if (ref $self->type_parameters->{TYPE} eq 'ARRAY')
		{
			$uri->media_type(sprintf('image/%s', lc $self->type_parameters->{TYPE}->[0]));
		}
		elsif (ref $self->type_parameters->{TYPE})
		{
			$uri->media_type(sprintf('image/%s', lc $self->type_parameters->{TYPE}));
		}
		else
		{
			$uri->media_type('application/octet-stream');
		}
		$uri->data( decode_base64($self->value->[0]) );
		return rdf_resource("$uri");
	}

	if (defined $self->type_parameters->{LANG})
	{
		return rdf_literal($self->value_to_string, $self->type_parameters->{LANG});
	}

	return rdf_literal($self->value_to_string);
}

sub property_node
{
	my ($self) = @_;
	
	return rdf_resource(V(lc $self->property))
		if lc $self->property =~ /^(adr|agent|email|geo|key|logo|
			n|org|photo|sound|tel|url|bday|category|class|fn|
			label|mailer|nickname|note|prodid|rev|role|sort\-string|
			title|tz|uid)$/xi;

	return rdf_resource(VX(lc $self->property))
		if lc $self->property =~ /^(kind|gender|sex|dday|
			anniversary|lang|member|caladruri|caluri|fburl|
			impp|source)$/xi;

	return rdf_resource(VX(lc $self->property))
		if lc $self->property =~ /^x-/;
	
	return;
}

{
	my %usage_type = (
		bbs      => V('BBS'),
		car      => V('Car'),
		cell     => V('Cell'),
		dom      => V('Dom'),
		fax      => V('Fax'),
		home     => V('Home'),
		internet => V('Internet'),
		intl     => V('Intl'),
		isdn     => V('ISDN'),
		modem    => V('Modem'),
		msg      => V('Msg'),
		pager    => V('Pager'),
		parcel   => V('Parcel'),
		pcs      => V('PCS'),
		postal   => V('Postal'),
		pref     => V('Pref'),
		video    => V('Video'),
		voice    => V('Voice'),
		work     => V('Work'),
		x400     => V('X400'),
		);

	my %intrinsic_type = (
		adr      => V('Address'),
		email    => V('Email'),
		impp     => VX('Impp'),
		label    => V('Label'),
		tel      => V('Tel'),
		);

	sub _add_to_model_typed_thing
	{
		my ($self, $model, $card_node) = @_;
		my $intermediate_node = RDF::Trine::Node::Blank->new;
		
		$model->add_statement(rdf_statement(
			$card_node,
			$self->property_node,
			$intermediate_node,
			));
		
		$model->add_statement(rdf_statement(
			$intermediate_node,
			rdf_resource(RDF('type')),
			rdf_resource($intrinsic_type{ lc $self->property }),
			))
			if $intrinsic_type{ lc $self->property };
		
		$model->add_statement(rdf_statement(
			$intermediate_node,
			rdf_resource(RDF('value')),
			$self->value_node,
			));
		
		if ($self->type_parameters)
		{
			foreach my $type (@{ $self->type_parameters->{TYPE} })
			{
				if ($usage_type{lc $type})
				{
					$model->add_statement(rdf_statement(
						$intermediate_node,
						rdf_resource(RDF('type')),
						rdf_resource($usage_type{lc $type}),
						));
				}
				$model->add_statement(rdf_statement(
					$intermediate_node,
					rdf_resource(VX('usage')),
					rdf_literal($type),
					));
			}
		}
		
		return $intermediate_node;  # useful for _add_to_model_ADR
	}

}

*_add_to_model_TEL   = \&_add_to_model_typed_thing;
*_add_to_model_EMAIL = \&_add_to_model_typed_thing;
*_add_to_model_LABEL = \&_add_to_model_typed_thing;
*_add_to_model_IMPP  = \&_add_to_model_typed_thing;

sub _add_to_model_AGENT
{
	warn "Outputting AGENT property to RDF not yet supported.";
}

sub _add_to_model_ADR
{
	my ($self, $model, $card_node) = @_;
	my $intermediate_node = $self->_add_to_model_typed_thing($model, $card_node);
	
	my @properties = (
		V('post-office-box'),
		V('extended-address'),
		V('street-address'),
		V('locality'),
		V('region'),
		V('postal-code'),
		V('country-name'),
		);
	my @components = @{ $self->nvalue };
	
	for (my $i=0; defined $properties[$i]; $i++)
	{
		next unless $components[$i] && @{ $components[$i] };
		
		foreach my $v (@{ $components[$i] })
		{
			$model->add_statement(rdf_statement(
				$intermediate_node,
				rdf_resource($properties[$i]),
				rdf_literal($v),
				));
		}
	}
	
	return $intermediate_node;
}

sub _add_to_model_GEO
{
	my ($self, $model, $card_node) = @_;
	my $intermediate_node = RDF::Trine::Node::Blank->new;
	
	my @properties = (
		V('latitude'),
		V('longitude'),
		);

	$model->add_statement(rdf_statement(
		$card_node,
		$self->property_node,
		$intermediate_node,
		));
	
	$model->add_statement(rdf_statement(
		$intermediate_node,
		rdf_resource(RDF('type')),
		rdf_resource(V('Location')),
		));

	my @components = @{ $self->nvalue };
	
	for (my $i=0; defined $properties[$i]; $i++)
	{
		next unless $components[$i] && @{ $components[$i] };
		
		foreach my $v (@{ $components[$i] })
		{
			$model->add_statement(rdf_statement(
				$intermediate_node,
				rdf_resource($properties[$i]),
				rdf_literal($v),
				));
		}
	}
		
	return $intermediate_node;
}

sub _add_to_model_N
{
	my ($self, $model, $card_node) = @_;
	my $intermediate_node = RDF::Trine::Node::Blank->new;
	
	my @properties = (
		V('family-name'),
		V('given-name'),
		V('additional-name'),
		V('honorific-suffix'),
		V('honorific-prefix'),
		);

	$model->add_statement(rdf_statement(
		$card_node,
		$self->property_node,
		$intermediate_node,
		));
	
	$model->add_statement(rdf_statement(
		$intermediate_node,
		rdf_resource(RDF('type')),
		rdf_resource(V('Name')),
		));

	my @components = @{ $self->nvalue };
	
	for (my $i=0; defined $properties[$i]; $i++)
	{
		next unless $components[$i] && @{ $components[$i] };
		
		foreach my $v (@{ $components[$i] })
		{
			$model->add_statement(rdf_statement(
				$intermediate_node,
				rdf_resource($properties[$i]),
				rdf_literal($v),
				));
		}
	}
	
	return $intermediate_node;
}

sub _add_to_model_ORG
{
	my ($self, $model, $card_node) = @_;

	my @units;
	foreach my $v1 (@{ $self->nvalue })
	{
		push @units, @$v1;
	}

	my $intermediate_node = RDF::Trine::Node::Blank->new;
	
	$model->add_statement(rdf_statement(
		$card_node,
		$self->property_node,
		$intermediate_node,
		));
	
	$model->add_statement(rdf_statement(
		$intermediate_node,
		rdf_resource(RDF('type')),
		rdf_resource(V('Organization')),
		));

	my $org = shift @units;

	if ($org)
	{
		$model->add_statement(rdf_statement(
			$intermediate_node,
			rdf_resource(V('organization-name')),
			rdf_literal($org),
			));
	}

	foreach my $u (@units)
	{
		$model->add_statement(rdf_statement(
			$intermediate_node,
			rdf_resource(V('organization-unit')),
			rdf_literal($u),
			));
	}
}

1;

__END__

=head1 NAME

RDF::vCard::Line - represents a line within a vCard

=head1 DESCRIPTION

Instances of this class correspond to lines within vCards, though
they could potentially be used as basis for other RFC 2425-based formats
such as iCalendar.

=head2 Constructor

=over

=item * C<< new(%options) >>

Returns a new RDF::vCard::Line object.

The only options worth worrying about are: B<property> (case-insensitive
property name), B<value> (arrayref or single string value), B<type_parameters>
(hashref of property-related parameters).

RDF::vCard::Entity overloads stringification, so you can do the following:

  my $line = RDF::vCard::Line->new(
    property        => 'email',
    value           => 'joe@example.net',
    type_parameters => { type=>['PREF','INTERNET'] },
    );
  print "$line\n" if $line =~ /internet/i;

=back

=head2 Methods

=over

=item * C<< to_string() >>

Formats the line according to RFC 2425 and RFC 2426.

=item * C<< add_to_model($model, $node) >>

Given an RDF::Trine::Model and an RDF::Trine::Node representing the
entity (i.e. vcard) that this line belongs to, adds triples to the
model for this line.

=item * C<< property() >>

Returns the line's property - e.g. "EMAIL".

=item * C<< property_node() >>

Returns the line's property as an RDF::Trine::Node that can be used as an
RDF predicate. Returns undef if a sensible URI cannot be found.

=item * C<< property_order() >>

Returns a string which can be used to sort a list of lines into a sensible
order.

=item * C<< value() >>

Returns an arrayref for the value. Each item in the arrayref could be a plain scalar,
or an arrayref of scalars. For example the arrayref representing this name:

  N:Smith;John;Edward,James

which is the vCard representation of somebody with surname Smith, given name
John and additional names (middle names) Edward and James, might be represented
with the following "value" arrayref:

  [
    'Smith',
    'John',
    ['Edward', 'James'],
  ]

or maybe:

  [
    ['Smith'],
    'John',
    ['Edward', 'James'],
  ]

That's why it's sometimes useful to have a normalised version of it...

=item * C<< nvalue() >>

Returns a normalised version of the arrayref for the value. It will always
be an arrayref of arrayrefs. For example:

  [
    ['Smith'],
    ['John'],
    ['Edward', 'James'],
  ]

=item * C<< value_node() >>

Returns the line's value as an RDF::Trine::Node that can be used as an
RDF object. For some complex properties (e.g. ADR, GEO, ORG, N, etc) the
result is not especially useful.

=item * C<< value_to_string() >>

Formats the line value according to RFC 2425 and RFC 2426.

=item * C<< type_parameters() >>

Returns the type_parameters hashref. Here be monsters (kinda).

=back

=head1 SEE ALSO

L<RDF::vCard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

