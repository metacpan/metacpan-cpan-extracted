use utf8;

package SemanticWeb::Schema::AnatomicalStructure;

# ABSTRACT: Any part of the human body

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'AnatomicalStructure';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has associated_pathophysiology => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'associatedPathophysiology',
);



has body_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'bodyLocation',
);



has connected_to => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'connectedTo',
);



has diagram => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'diagram',
);



has function => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'function',
);



has part_of_system => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'partOfSystem',
);



has related_condition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'relatedCondition',
);



has related_therapy => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'relatedTherapy',
);



has sub_structure => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'subStructure',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AnatomicalStructure - Any part of the human body

=head1 VERSION

version v3.8.1

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

=head2 C<body_location>

C<bodyLocation>

Location in the body of the anatomical structure.

A body_location should be one of the following types:

=over

=item C<Str>

=back

=head2 C<connected_to>

C<connectedTo>

Other anatomical structures to which this structure is connected.

A connected_to should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=back

=head2 C<diagram>

An image containing a diagram that illustrates the structure and/or its
component substructures and/or connections with other structures.

A diagram should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=back

=head2 C<function>

Function of the anatomical structure.

A function should be one of the following types:

=over

=item C<Str>

=back

=head2 C<part_of_system>

C<partOfSystem>

The anatomical or organ system that this structure is part of.

A part_of_system should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalSystem']>

=back

=head2 C<related_condition>

C<relatedCondition>

A medical condition associated with this anatomy.

A related_condition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalCondition']>

=back

=head2 C<related_therapy>

C<relatedTherapy>

A medical therapy related to this anatomy.

A related_therapy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

=back

=head2 C<sub_structure>

C<subStructure>

Component (sub-)structure(s) that comprise this anatomical structure.

A sub_structure should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
