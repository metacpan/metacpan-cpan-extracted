package RDF::Generator::Void::Stats;

use 5.006;
use strict;
use warnings;
use Moose;

=head1 NAME

RDF::Generator::Void::Stats - Generate statistics needed for good VoID descriptions

=head1 SYNOPSIS

Typically called for you by L<RDF::Generator::Void> as:

  my $stats = RDF::Generator::Void::Stats->new(generator => $self);


=head2 METHODS

=head3 C<< BUILD >>

Called by Moose to initialize an object.

=head3 C<generator>

Parameter to the constructor, to pass a L<RDF::Generator::Void> object.

=head3 C<vocabularies>

A hashref used to find common vocabularies in the data.

=head3 C<entities>

The number of distinct entities, as defined in the specification.

=head3 C<properties>

The number of distinct properties, as defined in the specification.

=head3 C<subjects>

The number of distinct subjects, as defined in the specification.

=head3 C<objects>

The number of distinct objects, as defined in the specification.

=head3 C<propertyPartitions>

A hashref containing the number of triples for each property.

=head3 C<classPartitions>

A hashref containing the number of triples for each class.


=cut

# The following attributes also act as read-write methods.
has vocabularies => ( is => 'rw', isa => 'HashRef' );

has ['entities', 'properties', 'subjects', 'objects'] => ( is => 'rw', isa => 'Int' );

has propertyPartitions => (is => 'rw', isa => 'HashRef' );

has classPartitions => (is => 'rw', isa => 'HashRef' );

# This is a read-only method, meaning that the constructor has it as a
# parameter, but then it can only be read from.
has generator => (
					 is       => 'ro',
					 isa      => 'RDF::Generator::Void',
					 required => 1,
					);

# The BUILD method is kinda the constructor. It is called when the
# user calls the constructor. In here, the statistics is generated.
sub BUILD {
	my ($self) = @_;

	# Initialize local hashes to count stuff.
	my (%vocab_counter, %entities, %properties, %subjects, %objects, %classes);

	my $gen = $self->generator;
	# Here, we take the data in the model we want to generate
	# statistics for and we iterate over it. Doing it this way, we
	# should be able to generate all statistics in a single pass of the
	# data.
	$gen->inmodel->get_statements->each(sub {
		my $st = shift;
		next unless $st->rdf_compatible; # To allow for non-RDF data models (e.g. N3)
		
		# wrap in eval, as this can potentially throw an exception.
		eval {
			my ($vocab_uri) = $st->predicate->qname;
			# The hash has a unique key, so now we count the number of qnames for each qname in the data
			$vocab_counter{$vocab_uri}++;
		};

		

		if ($gen->has_urispace && $st->subject->is_resource) {
			# Compute entities. We assume that all entities are subjects
			# with a prefix matching the uriSpace. Again, we use the
			# property that keys are unique, but we just set it to some
			# true value since we don't need to count how frequently each
			# entity is present.
			(my $urispace = $gen->urispace) =~ s/\./\\./g;
			$entities{$st->subject->uri_value} = 1 if ($st->subject->uri_value =~ m/^$urispace/);
		}
		
		$subjects{$st->subject->sse} = 1;
		$properties{$st->predicate->uri_value}{'triples'}++;
		$objects{$st->object->sse} = 1;

		if ((!$gen->has_level) || ($gen->has_level && $gen->level >= 1)) {
			if (($st->predicate->uri_value eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type')
				 && $st->object->is_resource) {
				$classes{$st->object->uri_value}++
			}
		}

		if ((!$gen->has_level) || ($gen->has_level && $gen->level > 2)) {
			$properties{$st->predicate->uri_value}{'countsubjects'}{$st->subject->sse} = 1;
			$properties{$st->predicate->uri_value}{'countobjects'}{$st->object->sse} = 1;
		}

	});

	# Finally, we update the attributes above, they are returned as a side-effect
	$self->vocabularies(\%vocab_counter);
	$self->entities(scalar keys %entities);
	$self->properties(scalar keys %properties);
	$self->subjects(scalar keys %subjects);
	$self->objects(scalar keys %objects);
	if ((!$gen->has_level) || ($gen->has_level && $gen->level >= 1)) {
		$self->propertyPartitions(\%properties);
		$self->classPartitions(\%classes);
	}
}

=head1 FURTHER DOCUMENTATION

Please see L<RDF::Generator::Void> for further documentation.

=head1 AUTHORS AND COPYRIGHT


Please see L<RDF::Generator::Void> for information about authors and copyright for this module.


=cut

1;
