package RDF::vCard::Entity;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);

use JSON qw[];
use RDF::TrineX::Functions
	-shortcuts,
	statement => { -as => 'rdf_statement' },
	iri       => { -as => 'rdf_resource' };

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
	$options{profile}    ||= 'VCARD';
	$options{lines}      ||= [];
	$options{components} ||= [];
	$options{node}       ||= $class->_node;
	bless { %options }, $class;
}

sub _node
{
	my ($class) = @_;
	return RDF::Trine::Node::Blank->new;
}

sub profile
{
	my ($self) = @_;
	return $self->{profile};
}

sub lines
{
	my ($self) = @_;
	return $self->{lines};
}

sub components
{
	my ($self) = @_;
	return $self->{components};
}

sub add
{
	my ($self, $line) = @_;
	push @{ $self->lines }, $line;
	$self->_entity_order_fu($line);	
	return $self;
}

sub add_component
{
	my ($self, $c) = @_;
	push @{ $self->components }, $c;
	return $self;
}

sub get
{
	my ($self, $property) = @_;
	return grep {
			lc $_->property eq lc $property
		} @{ $self->lines };
}

sub matches
{
	my ($self, $property, $regexp) = @_;
	return grep {
		$_->value_to_string =~ $regexp;
		} $self->get($property);
}

sub entity_order
{
	my ($self) = @_;
	
	return $self->{property}{'sort-string'}
		||  $self->{property}{'n'}
		||  $self->{property}{'n-faked'}
		||  $self->{property}{'fn'}
		||  $self->{property}{'nickname'};
}

sub _entity_order_fu
{
	my ($self, $line) = @_;
	
	if ($line->property =~ /^(sort.string|n|fn|nickname)$/i)
	{
		my $x = $line->value_to_string;
		$self->{property}{ lc $line->property } = $x if length $x;
		
		if (lc $line->property eq 'fn')
		{
			my @parts = split /\s+/, $x;
			my $last  = pop @parts;
			unshift @parts, $last;
			$self->{property}{'n-faked'} = join ';', @parts;
		}
	}
	return $self;
}

sub to_string
{
	my ($self) = @_;
	
	my @lines = sort {
		$a->property_order cmp $b->property_order;
		} @{$self->lines};

	my @components = sort {
		$a->entity_order cmp $b->entity_order;
		} @{$self->components};

	my $str = sprintf("BEGIN:%s\r\n", $self->profile);
	foreach my $line (@lines)
	{
		$str .= $line . "\r\n";
	}
	foreach my $component (@components)
	{
		$str .= $component;
	}
	$str .= sprintf("END:%s\r\n", $self->profile);
	
	return $str;
}

sub node
{
	my ($self) = @_;
	return $self->{node};
}

sub add_to_model
{
	my ($self, $model) = @_;
	
	$model->add_statement(rdf_statement(
		$self->node,
		rdf_resource( RDF('type') ),
		rdf_resource( V('VCard') ),
		));

	foreach my $line (@{ $self->lines })
	{
		$line->add_to_model($model, $self->node);
	}
	
	return $self;
}

sub to_jcard
{
	my ($self, $hashref) = @_;
	return ($hashref ? $self->TO_JSON : JSON::to_json($self));
}

{
	my @singular = qw(fn n bday tz geo sort-string uid class rev
		anniversary birth dday death gender kind prodid sex version);
	my @typed = qw(email tel adr label impp);
	
	sub TO_JSON
	{
		my ($self) = @_;
		my $object = {};
		
		foreach my $line (@{ $self->lines })
		{
			my $p = lc $line->property;
			
			if ($p eq 'n')
			{
				my $o;
				my @sp = qw(family-name given-name additional-name
					honorific-prefix honorific-suffix);
				for my $i (0..4)
				{
					if ($line->nvalue->[$i] and @{$line->nvalue->[$i]})
					{
						$o->{ $sp[$i] } = [ @{$line->nvalue->[$i]} ];
					}
				}
				push @{$object->{n}}, $o;
			}
			elsif ($p eq 'org')
			{
				my @components = map { $_->[0] } @{$line->nvalue};
				my $o = { 'organization-name' => shift @components };
				$o->{'organization-unit'} = \@components;
				push @{$object->{n}}, $o;
			}
			elsif ($p eq 'adr')
			{
				my $o;
				while (my ($k, $v) = each %{$line->type_parameters})
				{
					push @{$o->{$k}}, (ref $v eq 'ARRAY' ? @$v : $v);
				}
				if ($o->{type})
				{
					$o->{type} = [ sort map {lc $_} @{ $o->{type} } ]
				}
				my @sp = qw(post-office-box extended-address street-address
					locality region country-name postal-code);
				for my $i (0..6)
				{
					if ($line->nvalue->[$i] and @{$line->nvalue->[$i]})
					{
						$o->{ $sp[$i] } = [ @{$line->nvalue->[$i]} ];
					}
				}
				push @{$object->{adr}}, $o;
			}
			elsif ($p eq 'categories')
			{
				push @{$object->{categories}}, '@@TODO';
			}
			elsif ($p eq 'geo')
			{
				$object->{geo} = {
					latitude   => $line->nvalue->[0][0],
					longitude  => $line->nvalue->[1][0],
					};
			}
			elsif (grep { $_ eq $p } @typed)
			{
				my $o = {};
				while (my ($k, $v) = each %{$line->type_parameters})
				{
					push @{$o->{$k}}, (ref $v eq 'ARRAY' ? @$v : $v);
				}
				$o->{value} = $line->nvalue->[0][0];
				if ($o->{type})
				{
					$o->{type} = [ sort map {lc $_} @{ $o->{type} } ]
				}
				
				push @{ $object->{$p} }, $o;
			}
			elsif (grep { $_ eq $p } @singular)
			{
				$object->{$p} ||= $line->nvalue->[0][0];
			}
			else
			{
				push @{ $object->{$p} }, $line->nvalue->[0][0];
			}
		}
		
		return $object;
	}
}

1;

__END__

=head1 NAME

RDF::vCard::Entity - represents a single vCard

=head1 DESCRIPTION

Instances of this class correspond to individual vCard objects, though
it could potentially be used as basis for other RFC 2425-based formats
such as iCalendar.

=head2 Constructor

=over

=item * C<< new(%options) >>

Returns a new RDF::vCard::Entity object.

The only option worth worrying about is B<profile> which sets the
profile for the entity. This defaults to "VCARD".

RDF::vCard::Entity overloads stringification, so you can do the following:

  my $vcard = RDF::vCard::Entity->new;
  print $vcard if $vcard =~ /VCARD/i;

=back

=head2 Methods

=over

=item * C<< to_string() >>

Formats the object according to RFC 2425 and RFC 2426.

=item * C<< to_jcard() >>

Formats the object according to L<http://microformats.org/wiki/jcard>.

C<< to_jcard(1) >> will return the same data but without the JSON stringification.

=item * C<< add_to_model($model) >>

Given an RDF::Trine::Model, adds triples to the model for this entity.

=item * C<< node() >>

Returns an RDF::Trine::Node::Blank identifying this entity.

=item * C<< entity_order() >>

Returns a string along the lines of "Surname;Forename" useful for
sorting a list of entities.

=item * C<< profile() >>

Returns the entity type - e.g. "VCARD".

=item * C<< lines() >>

Returns an arrayref of L<RDF::vCard::Line> objects in the order they
were originally added.

This excludes the "BEGIN:VCARD" and "END:VCARD" lines.

=item * C<< add($line) >>

Add a L<RDF::vCard::Line>.

=item * C<< get($property) >>

Returns a list of L<RDF::vCard::Line> objects for the given property.

e.g.

  print "It has an address!\n" if ($vcard->get('ADR'));

=item * C<< matches($property, $regexp) >>

Checks to see if a property's value matches a regular expression.

  print "In London\n" if $vcard->matches(ADR => /London/);

=item * C<< add_component($thing) >>

Adds a nested entity within this one. This method is unused for vCard, but
is a hook for the benefit of L<RDF::iCalendar>.

=item * C<< components >>

Lists nested entities within this one.

=back

=begin private

=item TO_JSON

=end private

=head1 SEE ALSO

L<RDF::vCard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

