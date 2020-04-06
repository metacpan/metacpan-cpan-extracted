use utf8;

package SemanticWeb::Schema::AnatomicalStructure;

# ABSTRACT: Any part of the human body

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'AnatomicalStructure';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has associated_pathophysiology => (
    is        => 'rw',
    predicate => '_has_associated_pathophysiology',
    json_ld   => 'associatedPathophysiology',
);



has body_location => (
    is        => 'rw',
    predicate => '_has_body_location',
    json_ld   => 'bodyLocation',
);



has connected_to => (
    is        => 'rw',
    predicate => '_has_connected_to',
    json_ld   => 'connectedTo',
);



has diagram => (
    is        => 'rw',
    predicate => '_has_diagram',
    json_ld   => 'diagram',
);



has part_of_system => (
    is        => 'rw',
    predicate => '_has_part_of_system',
    json_ld   => 'partOfSystem',
);



has related_condition => (
    is        => 'rw',
    predicate => '_has_related_condition',
    json_ld   => 'relatedCondition',
);



has related_therapy => (
    is        => 'rw',
    predicate => '_has_related_therapy',
    json_ld   => 'relatedTherapy',
);



has sub_structure => (
    is        => 'rw',
    predicate => '_has_sub_structure',
    json_ld   => 'subStructure',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AnatomicalStructure - Any part of the human body

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

Any part of the human body, typically a component of an anatomical system.
Organs, tissues, and cells are all anatomical structures.

=head1 ATTRIBUTES

=head2 C<associated_pathophysiology>

C<associatedPathophysiology>

If applicable, a description of the pathophysiology associated with the
anatomical system, including potential abnormal changes in the mechanical,
physical, and biochemical functions of the system.

A associated_pathophysiology should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_associated_pathophysiology>

A predicate for the L</associated_pathophysiology> attribute.

=head2 C<body_location>

C<bodyLocation>

Location in the body of the anatomical structure.

A body_location should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_body_location>

A predicate for the L</body_location> attribute.

=head2 C<connected_to>

C<connectedTo>

Other anatomical structures to which this structure is connected.

A connected_to should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=back

=head2 C<_has_connected_to>

A predicate for the L</connected_to> attribute.

=head2 C<diagram>

An image containing a diagram that illustrates the structure and/or its
component substructures and/or connections with other structures.

A diagram should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=back

=head2 C<_has_diagram>

A predicate for the L</diagram> attribute.

=head2 C<part_of_system>

C<partOfSystem>

The anatomical or organ system that this structure is part of.

A part_of_system should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalSystem']>

=back

=head2 C<_has_part_of_system>

A predicate for the L</part_of_system> attribute.

=head2 C<related_condition>

C<relatedCondition>

A medical condition associated with this anatomy.

A related_condition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalCondition']>

=back

=head2 C<_has_related_condition>

A predicate for the L</related_condition> attribute.

=head2 C<related_therapy>

C<relatedTherapy>

A medical therapy related to this anatomy.

A related_therapy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

=back

=head2 C<_has_related_therapy>

A predicate for the L</related_therapy> attribute.

=head2 C<sub_structure>

C<subStructure>

Component (sub-)structure(s) that comprise this anatomical structure.

A sub_structure should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=back

=head2 C<_has_sub_structure>

A predicate for the L</sub_structure> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalEntity>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
