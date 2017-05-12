package RDF::Generator::Void;

use 5.006;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use Data::UUID;
use RDF::Trine qw[iri literal blank variable statement];
use RDF::Generator::Void::Stats;
# use less ();
use utf8;
use URI::Split qw(uri_split uri_join);

use aliased 'RDF::Generator::Void::Meta::Attribute::ObjectList';

# Define some namespace prefixes
my $void = RDF::Trine::Namespace->new('http://rdfs.org/ns/void#');
my $rdf  = RDF::Trine::Namespace->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
my $xsd  = RDF::Trine::Namespace->new('http://www.w3.org/2001/XMLSchema#');
my $dct  = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');
my $prov = RDF::Trine::Namespace->new('http://www.w3.org/ns/prov#');

=head1 NAME

RDF::Generator::Void - Generate VoID descriptions based on data in an RDF model

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.16';

=head1 SYNOPSIS

  use RDF::Generator::Void;
  use RDF::Trine::Model;
  my $mymodel   = RDF::Trine::Model->temporary_model;
  [add some data to $mymodel here]
  my $generator = RDF::Generator::Void->new(inmodel => $mymodel);
  $generator->urispace('http://example.org');
  $generator->add_endpoints('http://example.org/sparql');
  my $voidmodel = $generator->generate;

=head1 DESCRIPTION

This module takes a L<RDF::Trine::Model> object as input to the
constructor, and based on the data in that model as well as data
supplied by the user, it creates a new model with a VoID description
of the data in the model.

For a description of VoID, see L<http://www.w3.org/TR/void/>.

=head1 METHODS

=head2 new(inmodel => $mymodel, dataset_uri => URI->new($dataset_uri), level => 1);

The constructor. It can be called with two parameters, namely,
C<inmodel> which is a model we want to describe and C<dataset_uri>,
which is the URI we want to use for the description. Users should make
sure it is possible to get this with HTTP. If this is not possible,
you may leave this field empty so that a simple URN can be created for
you as a default.

=head2 C<inmodel>

Read-only accessor for the model used in description creation.

=head2 C<dataset_uri>

Read-only accessor for the URI to the dataset.

=cut

has inmodel => (
					 is       => 'ro',
					 isa      => 'RDF::Trine::Model',
					 required => 1,
					);

# This is setting up the dataset_uri method, and make it possible to
# create a resource of it from strings or URI objects.
class_type 'URI';

subtype 'DatasetURI',
  as 'Object',
  where { $_->isa('RDF::Trine::Node::Resource') || $_->isa('RDF::Trine::Node::Blank') };

coerce 'DatasetURI',
  from 'URI',    via { iri("$_") },
  from 'Str',    via { iri($_) };

has dataset_uri => (
						  is       => 'ro',
						  isa      => 'DatasetURI',
						  lazy     => 1,
						  builder  => '_build_dataset_uri',
						  coerce   => 1,
						 );

# This will create a URN with a UUID by default
sub _build_dataset_uri {
	my ($self) = @_;
	return iri sprintf('urn:uuid:%s', Data::UUID->new->create_str);
}

=head2 Property Attributes

The below attributes concern some essential properties in the VoID
vocabulary. They are mostly arrays, and can be manipulated using array
methods. Methods starting with C<all_> will return an array of unique
values. Methods starting with C<add_> takes a list of values to add,
and those starting with C<has_no_> return a boolean value, false if
the array is empty.

=head3 C<all_vocabularies>, C<add_vocabularies>, C<has_no_vocabularies>

Methods to manipulate a list of vocabularies used in the dataset. The
values should be a string that represents the URI of a vocabulary.

=cut

# All the following attributes have that in common that they
# automatically the method names also specified in handles, to
# manipulate and query the data.
has _vocabularies => ( traits => [ObjectList] );

=head3 C<all_endpoints>, C<add_endpoints>, C<has_no_endpoints>

Methods to manipulate a list of SPARQL endpoints that can be used to
query the dataset. The values should be a string that represents the
URI of a SPARQL endpoint.

=cut


has _endpoints => ( traits => [ObjectList] );

=head3 C<all_titles>, C<add_titles>, C<has_no_titles>

Methods to manipulate the titles of the datasets. The values should be
L<RDF::Trine::Node::Literal> objects, and should be set with
language. Typically, you would have a value per language.

=cut


has _titles => ( 
				  traits => [ObjectList],
				  isa      => 'ArrayRef[RDF::Trine::Node::Literal]',
				 );


=head3 C<all_licenses>, C<add_licenses>, C<has_no_licenses>

Methods to manipulate a list of licenses that regulates the use of the
dataset. The values should be a string that represents the URI of a
license.

=cut

has _licenses => ( traits => [ObjectList] );

=head3 C<urispace>, C<has_urispace>

This method is used to set the URI prefix string that will match the
entities in your dataset. The computation of the number of entities
depends on this being set. C<has_urispace> can be used to check if it
is set.

=cut

# There should only be a single uriSpace per Dataset (but there may be
# more for subsets), thus this is a simple scalar attribute.
has urispace => (
					  is        => 'rw',
					  isa       => 'Str',
					  predicate => 'has_urispace',
					 );

=head2 Running this stuff

=head3 C<level>, C<has_level>

Set the level of detail. 0 doesn't do any statistics or heuristics, 1
has some statistics for the dataset as a whole, 2 will give some
partition statistics and 3 will give subject and object counts for
property partitions. Setting no level will give everything.

=cut

has level => (is => 'rw', isa => 'Int', predicate => 'has_level');


=head3 C<stats>, C<clear_stats>, C<has_stats>

Method to compute a statistical summary for the data in the dataset,
such as the number of entities, predicates, etc. C<clear_stats> will
clear the statistics and C<has_stats> will return true if exists.

=cut

# In practice, this method just calls the ::Stats class to do
# everything.
has stats => (
				  is       => 'rw',
				  isa      => 'RDF::Generator::Void::Stats',
				  lazy     => 1,
				  builder  => '_build_stats',
				  clearer  => 'clear_stats',
				  predicate => 'has_stats',
				 );

sub _build_stats {
	my ($self) = @_;
	return RDF::Generator::Void::Stats->new(generator => $self);
}


=head3 generate( [ $model ] )

Returns the VoID as an RDF::Trine::Model. You may pass a model with
statements as argument to this method. This model may then contain
arbitrary RDF that will be added to the RDF model. If you do not send
a model, one will be created for you.

=cut

sub generate {
	my $self = shift;
	my $void_model = shift || RDF::Trine::Model->temporary_model;

	local $self->{void_model} = $void_model;

	# Start generating the actual VoID statements
	$void_model->add_statement(statement(
													 $self->dataset_uri,
													 $rdf->type,
													 $void->Dataset,
													));

	my ($scheme, $auth, $path, $query, $frag) = uri_split($self->dataset_uri->uri_value);
	if ($frag) { # Then, we have a document that could be described with provenance
		my $uri = iri(uri_join($scheme, $auth, $path, $query, undef));
		my $blank = blank();
		$void_model->add_statement(statement($uri,
														 $prov->wasGeneratedBy,
														 $blank));
		(my $ver = $VERSION) =~ s/\./-/;
		my $release_uri = iri("http://purl.org/NET/cpan-uri/dist/RDF-Generator-Void/v_$ver");
		$void_model->add_statement(statement($blank,
														 $prov->wasAssociatedWith,
														 $release_uri));
		$void_model->add_statement(statement($release_uri,
														 $rdf->type,
													    $prov->SoftwareAgent));
		$void_model->add_statement(statement($release_uri,
														 iri('http://www.w3.org/2000/01/rdf-schema#label'),
													    literal("RDF::Generator::Void, Version $VERSION", 'en')));
	}


	foreach my $endpoint ($self->all_endpoints) {
		$void_model->add_statement(statement(
														 $self->dataset_uri,
														 $void->sparqlEndpoint,
														 iri($endpoint)
														));
	}

	foreach my $title ($self->all_titles) {
		$void_model->add_statement(statement(
														 $self->dataset_uri,
														 $dct->title,
														 $title
														));
	}
 
	foreach my $license ($self->all_licenses) {
		$void_model->add_statement(statement(
														 $self->dataset_uri,
														 $dct->license,
														 iri($license)
														));
	}


	$void_model->add_statement(statement(
													 $self->dataset_uri,
													 $void->triples,
													 literal($self->inmodel->size, undef, $xsd->integer),
													));

	if ($self->has_urispace) {
		$void_model->add_statement(statement(
														 $self->dataset_uri,
														 $void->uriSpace,
														 literal($self->urispace)
														));
		return $void_model if ($self->has_level && ($self->level == 0));
		$self->_generate_counts($void->entities, $self->stats->entities);
	}

	return $void_model if ($self->has_level && $self->level == 0);
	$self->_generate_counts($void->distinctSubjects, $self->stats->subjects);
	$self->_generate_counts($void->properties, $self->stats->properties);
	$self->_generate_counts($void->distinctObjects, $self->stats->objects);

	$self->_generate_most_common_vocabs($self->stats) if $self->has_stats;

	return $void_model if ($self->has_level && $self->level <= 1);

	$self->_generate_propertypartitions;
	$self->_generate_classpartitions;
	return $void_model;
}

sub _generate_counts {
	my ($self, $predicate, $count) = @_;
	return undef unless $self->has_stats;
	$self->{void_model}->add_statement(statement(
																$self->dataset_uri,
																$predicate,
																literal($count, undef, $xsd->integer),
															  ));
}

sub _generate_propertypartitions {
  my ($self) = @_;
  return undef unless $self->has_stats;
  my $properties = $self->stats->propertyPartitions;
  while (my ($uri, $counts) = each(%{$properties})) {
    my $blank = blank();
    $self->{void_model}->add_statement(statement(
						 $self->dataset_uri,
						 $void->propertyPartition,
						 $blank));
    $self->{void_model}->add_statement(statement($blank,
						 $void->property,
						 iri($uri)));
    $self->{void_model}->add_statement(statement($blank,
						 $void->triples,
						 literal($counts->{'triples'}, undef, $xsd->integer)));
	 # OK, so sometimes, one has to balance elegance and performance...
	 if ($counts->{'countsubjects'}) {
		 $self->{void_model}->add_statement(statement($blank,
						 $void->distinctSubjects,
						 literal(scalar keys %{$counts->{'countsubjects'}}, undef, $xsd->integer)));
		 $self->{void_model}->add_statement(statement($blank,
						 $void->distinctObjects,
						 literal(scalar keys %{$counts->{'countobjects'}}, undef, $xsd->integer)));
	 }

		 

  }
}

sub _generate_classpartitions {
  my ($self) = @_;
  return undef unless $self->has_stats;
  my $classes = $self->stats->classPartitions;
  while (my ($uri, $count) = each(%{$classes})) {
    my $blank = blank();
    $self->{void_model}->add_statement(statement(
						 $self->dataset_uri,
						 $void->classPartition,
						 $blank));
    $self->{void_model}->add_statement(statement($blank,
						 $void->class,
						 iri($uri)));
    $self->{void_model}->add_statement(statement($blank,
						 $void->triples,
						 literal($count, undef, $xsd->integer)));
  }
}

sub _generate_most_common_vocabs {
	my ($self) = @_;

	# Which vocabularies are most commonly used for predicates in the
	# dataset? Vocabularies used for less than 1% of triples need not
	# apply.
	my $threshold = $self->inmodel->size / 100;
	my %vocabs    = %{ $self->stats->vocabularies };
	$self->add_vocabularies(grep { $vocabs{$_} > $threshold } keys %vocabs);
  
	foreach my $vocab ($self->all_vocabularies) {
		$self->{void_model}->add_statement(statement(
																	$self->dataset_uri,
																	$void->vocabulary,
																	iri($vocab),
																  ));
	}
}


=head1 AUTHORS

Kjetil Kjernsmo C<< <kjetilk@cpan.org> >>
Toby Inkster C<< <tobyink@cpan.org> >>

=head1 TODO

=over

=item * URI regexps support.

=item * Technical features (esp. serializations).

=item * Example resources and root resources.

=item * Data dumps.

=item * Subject classification.

=item * Method to disable heuristics.

=item * More heuristics.

=item * Linkset descriptions.

=item * Set URI space on partitions.

=item * Use L<CHI> to cache?

=item * Use schema introspection to generate property attributes with L<MooseX::Semantic>.



=back


=head1 BUGS

Please report any bugs you find to L<https://github.com/kjetilk/RDF-Generator-Void/issues>

Note that any claim that this module will generate a void in
spacetime, a wormhole, black hole, or funny philosophy is totally
bogus and without any scientific merit whatsoever. The lead author has
made elaborate precautions to avoid any such issues, and expects
everyone to take his word for it. Oh, BTW, should it just happen
anyway, it won't L<hurt much|http://news.sciencemag.org/sciencenow/2012/03/scienceshot-one-black-hole-wont-.html>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RDF::Generator::Void

The Perl and RDF community website is at L<http://www.perlrdf.org/>
where you can also find a mailing list to direct questions to.

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RDF-Generator-Void>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RDF-Generator-Void>

=item * MetaCPAN

L<https://metacpan.org/module/RDF::Generator::Void>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to Konstantin Baierer for help with L<RDF::Generator::Void::Meta::Attribute::ObjectList>.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Toby Inkster.
Copyright 2012,2013,2016 Kjetil Kjernsmo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;										  # End of RDF::Generator::Void
