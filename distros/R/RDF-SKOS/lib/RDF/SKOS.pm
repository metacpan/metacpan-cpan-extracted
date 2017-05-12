package RDF::SKOS;

use warnings;
use strict;

use Data::Dumper;

use RDF::SKOS::Concept;
use RDF::SKOS::Scheme;

=head1 NAME

RDF::SKOS - SKOS - Simple Knowledge Organization System

=head1 SYNOPSIS

    use RDF::SKOS;
    my $skos = new RDF::SKOS;

    # adding one
    $skos->concept ('aaa' => { prefLabels => [ [ 'xxx', 'de' ] ] });

    # regain it
    my $c = $skos->concept ('aaa');

    # get all of them
    my @cs = $skos->concepts;

    # label stuff
    @labels = $c->prefLabels;
    @labels = $c->altLabels;
    @labels = $c->hiddenLabels;

    @labels = $c->notes;
    @labels = $c->scopeNotes;
    @labels = $c->definitions;
    @labels = $c->examples;
    @labels = $c->historyNotes;
    @labels = $c->editorialNotes;
    @labels = $c->changeNotes;

    # broader/narrower
    @cs = $c->narrower
    @cs = $c->narrowerTransitive
    @cs = $c->broader
    @cs = $c->broaderTransitive

    # associated
    @cs = $c->related
    @cs = $c->relatedTransitive

    # get all schemes
    @ss = $skos->schemes
    # get a particular
    $sch = $skos->scheme ('some_scheme');
    # find top-level concepts
    @tops = $skos->topConcepts ('some_scheme');


=head1 DESCRIPTION

!!! DEVELOPER RELEASE (THERE MAY BE DRAGONS) !!!

!!! PLEASE SEE THE README FOR LIMITATIONS    !!!

SKOS is a model for expressing very basic concept schemes, much simpler than Topic Maps or RDF. This
includes subject headings, taxonomies, folksonomies. For a primer see

=begin html

<a href="http://www.w3.org/TR/skos-primer/">SKOS Primer</a>

=end html

=head2 Overview

This package suite supports SKOS in that:

=over

=item

It provides packages with particular SKOS data,

=item

It implements SKOS on top of various RDF stores, so that you can read RDF and enjoy an I<SKOS
view> on top of that,

=item

Or you can derive your own subclasses of the generic L<RDF::SKOS>, especially for the case
where you have a different format.

=back

=head2 Concept Identification

This implementation assumes that each concept has a unique ID. That is simply a scalar.

=head2 Caveats

Following things are not yet added:

=over

=item 

At the moment there is mostly read-only support. You can add concepts to the SKOS, but there is no
proper interface for added/removing concepts, or schemes.

=item

There is also no support for collections yet.

=item

And none for all *Match relationships between concepts.

=item

And most of the SKOS constraints are not yet honored.

=back

If you need any of that, please throw obscene amounts of (good) chocolate into my direction. Or
write a patch! No. Better send chocolate.

=head1 INTERFACE

=head2 Constructor

The constructor does not expect any additional information.

Example:

  my $skos = new RDF::SKOS;

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=pod

=head2 Methods

=over

=item B<concept>

I<$c> = I<$skos>->concept ('xyz')

Given the ID of the concept, this method returns an L<RDF::SKOS::Concept> object representing the
concept. If there is no such concept C<undef> will be returned.

If - apart from the ID - another parameter is added, that must be a HASH reference carrying all the
attributes for that concept. That concept will be stored under this ID. If there was already
something there, it will be overwritten.

=cut

sub concept {
    my $self = shift;
    my $ID   = shift;
    my $info = shift;
    if ($info) {
	die "concept" unless ref ($info) eq 'HASH';
	my $c    = new RDF::SKOS::Concept ($self, $ID, %$info);
	return $self->{concepts}->{$ID} = $c;
    } else {
	return $self->{concepts}->{$ID};
    }
}

=pod

=item B<concepts>

I<@concepts> = I<$skos>->concepts

This method return a list of L<RDF::SKOS::Concept> objects, each for a concept in the SKOS.

=cut

sub concepts {
    die "this must be implemented by a subclass";
}

=back

=head2 Scheme-Related Methods

=over

=item B<schemes>

I<@schemes> = I<$skos>->schemes

This will return a list of L<RDF::SKOS::Scheme> objects which all represent one scheme within the
SKOS.

=cut

sub schemes {
    return ();
}

=pod

=item B<scheme>

I<$scheme> = I<$skos>->scheme (I<ID>)

Returns the scheme object for the one with that ID.

=cut

sub scheme {
    return ();
}

=pod

=item B<topConcepts>

I<@tops> = I<$skos>->topConcepts ('scheme_a')

Given the ID of a concept scheme, this will return a list of L<RDF::SKOS::Concept> objects
representing the top-level concepts in that scheme.

=cut

sub topConcepts {
    return ();
}

=pod

=back

=head2 Concept-Related Methods

All these methods expect the concept ID to be passed in as the sole parameter:

I<@labels> = I<$skos>->prefLabels ('some-concept') 

Out comes a list of tuples. Each tuple contains first the value, then the language tag, both as
scalars.

=over

=item B<prefLabels>

Returns the list of preferred labels.

=cut

sub prefLabels {
    my $self = shift;
    my $cid  = shift;
    my $c    = $self->{concepts}->{$cid};
    return $c->{prefLabels} ? @{ $c->{prefLabels} } : ();
}

=pod

=item B<altLabels>

Returns the list of alternative labels.

=cut

sub altLabels {
    my $self = shift;
    my $cid  = shift;
    my $c    = $self->{concepts}->{$cid};
    return $c->{altLabels} ? @{ $c->{altLabels} } : ();
}

=pod

=item B<hiddenLabels>

Returns the list of hidden labels.

=cut

sub hiddenLabels {
    my $self = shift;
    my $cid  = shift;
    my $c    = $self->{concepts}->{$cid};
    return $c->{hiddenLabels} ? @{ $c->{hiddenLabels} } : ();
}

=pod

=item B<notes>

Returns the list of notes.

B<NOTE>: No property subclassing is honored, so scopeNotes are NOT included (yet).

=cut

sub notes {
    my $self = shift;
    my $cid  = shift;
    my $c    = $self->{concepts}->{$cid};
    return $c->{notes} ? @{ $c->{notes} } : ();
}

=pod

=item B<scopeNotes>

Returns the list of scope notes.

=cut

sub scopeNotes {
    my $self = shift;
    my $cid  = shift;
    my $c    = $self->{concepts}->{$cid};
    return $c->{scopeNotes} ? @{ $c->{scopeNotes} } : ();
}

=pod

=item B<definitions>

Returns the list of definitions.

=cut

sub definitions {
    my $self = shift;
    my $cid  = shift;
    my $c    = $self->{concepts}->{$cid};
    return $c->{definitions} ? @{ $c->{definitions} } : ();
}

=pod

=item B<examples>

Returns the list of examples.

=cut

sub examples {
    my $self = shift;
    my $cid  = shift;
    my $c    = $self->{concepts}->{$cid};
    return $c->{examples} ? @{ $c->{examples} } : ();
}

=pod

=item B<historyNotes>

Returns the list of history notes.

=cut

sub historyNotes {
    my $self = shift;
    my $cid  = shift;
    my $c    = $self->{concepts}->{$cid};
    return $c->{historyNotes} ? @{ $c->{historyNotes} } : ();
}

=pod

=item B<editorialNotes>

Returns the list of editorial notes.

=cut

sub editorialNotes {
    my $self = shift;
    my $cid  = shift;
    my $c    = $self->{concepts}->{$cid};
    return $c->{editorialNotes} ? @{ $c->{editorialNotes} } : ();
}

=pod

=item B<changeNotes>

Returns the list of change notes.

=cut

sub changeNotes {
    my $self = shift;
    my $cid  = shift;
    my $c    = $self->{concepts}->{$cid};
    return $c->{changeNotes} ? @{ $c->{changeNotes} } : ();
}

=pod

=back

=head2 Taxonometrical Methods

=over

=item B<narrower>/B<broader>

I<$cs> = I<$skos>->narrower           (I<$ID>)

I<$cs> = I<$skos>->narrowerTransitive (I<$ID>)

I<$cs> = I<$skos>->broader            (I<$ID>)

I<$cs> = I<$skos>->broaderTransitive  (I<$ID>)

This method expects the ID of a concept and returns a list of L<RDF::SKOS::Concept> objects which
have a C<narrower> relationship to that with ID. As the semantics of I<narrower> involves that it is
the inverse of I<broader> also these relationships are respected.

If you want I<narrower>/I<broader> to be interpreted transitively, then use the variant
C<narrowerTransitive>. That not only interprets everything transitively, it also picks up the
I<narrowTransitive> relationships inside the SKOS object.

B<NOTE>: I understand that this deviates somewhat from the standard. But it makes life easier.

=cut

sub narrower {
    return ();
}

=pod

=item B<narrowerTransitive>

See above

=cut

sub narrowerTransitive {
    return ();
}

=pod

=item B<broader>

See above

=cut

sub broader {
    return ();
}

=pod

=item B<broaderTransitive>

See above

=cut

sub broaderTransitive {
    return ();
}

=pod

=back

=head2 Associative Methods

=over

=item B<related>

This method expects the ID of a concept and returns a list of L<RDF::SKOS::Concept> objects which
have a C<related> relationship to that identified with ID. Note that I<related> is always symmetric,
not not automatically transitive. If you want transitivity to be honored, then use the variant
C<relatedTransitive>.

B<NOTE>: This interpretation is fully SKOS compliant.

=cut

sub related {
    return ();
}

=pod

=item B<relatedTransitive>

See above

=cut

sub relatedTransitive {
    return ();
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <drrho at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rdf-skos at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-SKOS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION = '0.03';

"against all odds";

__END__

 =head2 Match-Related Methods

 =over

 =cut

sub relatedMatch {
    return ();
}

sub exactMatch {
    return ();
}

sub closeMatch {
    return ();
}

sub broadMatch {
    return ();
}

sub narrowMatch {
    return ();
}

 =pod

 =back

