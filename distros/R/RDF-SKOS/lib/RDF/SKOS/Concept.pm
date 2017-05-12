package RDF::SKOS::Concept;

use strict;
use warnings;

=head1 NAME

RDF::SKOS::Concept - SKOS - Concept Class

=head1 SYNOPSIS

    use RDF::SKOS;
    my $skos = new RDF::SKOS;
    my $c = $skos->concept ('aaa');

    @labels = $c->prefLabels;
    # see RDF::SKOS for other concept related methods

=head1 DESCRIPTION

This class is simply a container for SKOS concepts. Usually, these
concepts have various labels, descriptions, etc. And they can be
related, generally, or more specifically with a I<narrower>,
I<broader> relationship.

This class simply gives access to this information. At the moment this
is all read only, except the constructor maybe.

=head1 INTERFACE

=head2 Constructor

The constructor expects as first parameter the SKOS object itself, then the ID of the concept. What
follows then is a hash reference containing the concept information, such as I<prefLabels>,
I<altLabels> etc. This information is added in the same way as described in L<RDF::SKOS>, namely as
list (reference) to tuples. The tuples containing the label itself, then the language tag.

=cut

sub new {
    my $class = shift;
    my $skos  = shift;
    my $cid   = shift;
    return bless { @_, skos => $skos, id => $cid }, $class;
}

=pod

=head2 Methods

All these methods are effectively passing on onto the underlying L<RDF::SKOS> object. Labels
are always lists of tuples.

=over

=item B<prefLabels>

I<@ls> = I<$c>->prefLabels

=cut

sub prefLabels {
    my $self = shift;
    my $skos = $self->{skos};
    return $skos->prefLabels ($self->{id});
}

=pod

=item B<altLabels>

I<@ls> = I<$c>->altLabels

=cut

sub altLabels {
    my $self = shift;
    my $skos = $self->{skos};
    return $skos->altLabels ($self->{id});
}

=pod

=item B<hiddenLabels>

I<@ls> = I<$c>->hiddenLabels

=cut

sub hiddenLabels {
    my $self = shift;
    my $skos = $self->{skos};
    return $skos->hiddenLabels ($self->{id});
}

=pod

=item B<scopeNotes>

I<@ls> = I<$c>->scopeNotes

=cut

sub scopeNotes {
    my $self = shift;
    my $skos = $self->{skos};
    return $skos->scopeNotes ($self->{id});
}

=pod

=item B<notes>

I<@ls> = I<$c>->notes

=cut

sub notes {
    my $self = shift;
    my $skos = $self->{skos};
    return $skos->notes ($self->{id});
}

=pod

=item B<definitions>

I<@ls> = I<$c>->definitions

=cut

sub definitions {
    my $self = shift;
    my $skos = $self->{skos};
    return $skos->definitions ($self->{id});
}

=pod

=item B<examples>

I<@ls> = I<$c>->examples

=cut

sub examples {
    my $self = shift;
    my $skos = $self->{skos};
    return $skos->examples ($self->{id});
}

=pod

=item B<historyNotes>

I<@ls> = I<$c>->historyNotes

=cut

sub historyNotes {
    my $self = shift;
    my $skos = $self->{skos};
    return $skos->historyNotes ($self->{id});
}

=pod

=item B<editorialNotes>

I<@ls> = I<$c>->editorialNotes

=cut

sub editorialNotes {
    my $self = shift;
    my $skos = $self->{skos};
    return $skos->editorialNotes ($self->{id});
}

=pod

=item B<changeNotes>

I<@ls> = I<$c>->changeNotes

=cut

sub changeNotes {
    my $self = shift;
    my $skos = $self->{skos};
    return $skos->changeNotes ($self->{id});
}

=pod

=item B<narrower>

I<@cs> = I<$c>->narrower

=cut

sub narrower {
    my $self = shift;
    return $self->{skos}->narrower ($self->{id});
}

=pod

=item B<narrowerTransitive>

I<@cs> = I<$c>->narrowerTransitive

=cut

sub narrowerTransitive {
    my $self = shift;
    return $self->{skos}->narrowerTransitive ($self->{id});
}

=pod

=item B<broader>

I<@cs> = I<$c>->broader

=cut

sub broader {
    my $self = shift;
    return $self->{skos}->broader ($self->{id});
}

=pod

=item B<broaderTransitive>

I<@cs> = I<$c>->broaderTransitive

=cut

sub broaderTransitive {
    my $self = shift;
    return $self->{skos}->broaderTransitive ($self->{id});
}

=pod

=item B<related>

I<@cs> = I<$c>->related

=cut

sub related {
    my $self = shift;
    return $self->{skos}->related ($self->{id})
}

=pod

=item B<relatedTransitive>

I<@cs> = I<$c>->relatedTransitive

=cut

sub relatedTransitive {
    my $self = shift;
    return $self->{skos}->relatedTransitive ($self->{id})
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

our $VERSION = '0.01';

"against all odds";

__END__

sub relatedMatch {
    my $self = shift;
    return $self->{skos}->relatedMatch ($self->{id})
}

sub exactMatch {
    my $self = shift;
    return $self->{skos}->exactMatch ($self->{id})
}

sub closeMatch {
    my $self = shift;
    return $self->{skos}->closeMatch ($self->{id})
}

sub broadMatch {
    my $self = shift;
    return $self->{skos}->broadMatch ($self->{id})
}

sub narrowMatch {
    my $self = shift;
    return $self->{skos}->narrowMatch ($self->{id})
}

