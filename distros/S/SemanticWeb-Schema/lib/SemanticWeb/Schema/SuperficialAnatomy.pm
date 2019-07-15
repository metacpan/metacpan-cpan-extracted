use utf8;

package SemanticWeb::Schema::SuperficialAnatomy;

# ABSTRACT: Anatomical features that can be observed by sight (without dissection)

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'SuperficialAnatomy';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has associated_pathophysiology => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'associatedPathophysiology',
);



has related_anatomy => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'relatedAnatomy',
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



has significance => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'significance',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SuperficialAnatomy - Anatomical features that can be observed by sight (without dissection)

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Anatomical features that can be observed by sight (without dissection),
including the form and proportions of the human body as well as surface
landmarks that correspond to deeper subcutaneous structures. Superficial
anatomy plays an important role in sports medicine, phlebotomy, and other
medical specialties as underlying anatomical structures can be identified
through surface palpation. For example, during back surgery, superficial
anatomy can be used to palpate and count vertebrae to find the site of
incision. Or in phlebotomy, superficial anatomy can be used to locate an
underlying vein; for example, the median cubital vein can be located by
palpating the borders of the cubital fossa (such as the epicondyles of the
humerus) and then looking for the superficial signs of the vein, such as
size, prominence, ability to refill after depression, and feel of
surrounding tissue support. As another example, in a subluxation
(dislocation) of the glenohumeral joint, the bony structure becomes
pronounced with the deltoid muscle failing to cover the glenohumeral joint
allowing the edges of the scapula to be superficially visible. Here, the
superficial anatomy is the visible edges of the scapula, implying the
underlying dislocation of the joint (the related anatomical structure).

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

=head2 C<related_anatomy>

C<relatedAnatomy>

Anatomical systems or structures that relate to the superficial anatomy.

A related_anatomy should be one of the following types:

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

=head2 C<related_therapy>

C<relatedTherapy>

A medical therapy related to this anatomy.

A related_therapy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

=back

=head2 C<significance>

The significance associated with the superficial anatomy; as an example,
how characteristics of the superficial anatomy can suggest underlying
medical conditions or courses of treatment.

A significance should be one of the following types:

=over

=item C<Str>

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
