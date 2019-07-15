use utf8;

package SemanticWeb::Schema::MedicalDevice;

# ABSTRACT: Any object used in a medical capacity

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalDevice';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has adverse_outcome => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'adverseOutcome',
);



has contraindication => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'contraindication',
);



has indication => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'indication',
);



has post_op => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'postOp',
);



has pre_op => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'preOp',
);



has procedure => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'procedure',
);



has purpose => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'purpose',
);



has serious_adverse_outcome => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seriousAdverseOutcome',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalDevice - Any object used in a medical capacity

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Any object used in a medical capacity, such as to diagnose or treat a
patient.

=head1 ATTRIBUTES

=head2 C<adverse_outcome>

C<adverseOutcome>

A possible complication and/or side effect of this therapy. If it is known
that an adverse outcome is serious (resulting in death, disability, or
permanent damage; requiring hospitalization; or is otherwise
life-threatening or requires immediate medical attention), tag it as a
seriouseAdverseOutcome instead.

A adverse_outcome should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEntity']>

=back

=head2 C<contraindication>

A contraindication for this therapy.

A contraindication should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalContraindication']>

=item C<Str>

=back

=head2 C<indication>

A factor that indicates use of this therapy for treatment and/or prevention
of a condition, symptom, etc. For therapies such as drugs, indications can
include both officially-approved indications as well as off-label uses.
These can be distinguished by using the ApprovedIndication subtype of
MedicalIndication.

A indication should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalIndication']>

=back

=head2 C<post_op>

C<postOp>

A description of the postoperative procedures, care, and/or followups for
this device.

A post_op should be one of the following types:

=over

=item C<Str>

=back

=head2 C<pre_op>

C<preOp>

A description of the workup, testing, and other preparations required
before implanting this device.

A pre_op should be one of the following types:

=over

=item C<Str>

=back

=head2 C<procedure>

A description of the procedure involved in setting up, using, and/or
installing the device.

A procedure should be one of the following types:

=over

=item C<Str>

=back

=head2 C<purpose>

A goal towards an action is taken. Can be concrete or abstract.

A purpose should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalDevicePurpose']>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<serious_adverse_outcome>

C<seriousAdverseOutcome>

A possible serious complication and/or serious side effect of this therapy.
Serious adverse outcomes include those that are life-threatening; result in
death, disability, or permanent damage; require hospitalization or prolong
existing hospitalization; cause congenital anomalies or birth defects; or
jeopardize the patient and may require medical or surgical intervention to
prevent one of the outcomes in this definition.

A serious_adverse_outcome should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEntity']>

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
