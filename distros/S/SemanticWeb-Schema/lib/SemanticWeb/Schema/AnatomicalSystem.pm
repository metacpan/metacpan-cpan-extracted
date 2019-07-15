use utf8;

package SemanticWeb::Schema::AnatomicalSystem;

# ABSTRACT: An anatomical system is a group of anatomical structures that work together to perform a certain task

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'AnatomicalSystem';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has associated_pathophysiology => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'associatedPathophysiology',
);



has comprised_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'comprisedOf',
);



has related_condition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'relatedCondition',
);



has related_structure => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'relatedStructure',
);



has related_therapy => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'relatedTherapy',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AnatomicalSystem - An anatomical system is a group of anatomical structures that work together to perform a certain task

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

An anatomical system is a group of anatomical structures that work together
to perform a certain task. Anatomical systems, such as organ systems, are
one organizing principle of anatomy, and can includes circulatory,
digestive, endocrine, integumentary, immune, lymphatic, muscular, nervous,
reproductive, respiratory, skeletal, urinary, vestibular, and other
systems.

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

=head2 C<comprised_of>

C<comprisedOf>

Specifying something physically contained by something else. Typically used
here for the underlying anatomical structures, such as organs, that
comprise the anatomical system.

A comprised_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalSystem']>

=back

=head2 C<related_condition>

C<relatedCondition>

A medical condition associated with this anatomy.

A related_condition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalCondition']>

=back

=head2 C<related_structure>

C<relatedStructure>

Related anatomical structure(s) that are not part of the system but relate
or connect to it, such as vascular bundles associated with an organ system.

A related_structure should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=back

=head2 C<related_therapy>

C<relatedTherapy>

A medical therapy related to this anatomy.

A related_therapy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

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
