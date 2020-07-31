use utf8;

package SemanticWeb::Schema::TherapeuticProcedure;

# ABSTRACT: A medical procedure intended primarily for therapeutic purposes

use Moo;

extends qw/ SemanticWeb::Schema::MedicalProcedure /;


use MooX::JSON_LD 'TherapeuticProcedure';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has adverse_outcome => (
    is        => 'rw',
    predicate => '_has_adverse_outcome',
    json_ld   => 'adverseOutcome',
);



has dose_schedule => (
    is        => 'rw',
    predicate => '_has_dose_schedule',
    json_ld   => 'doseSchedule',
);



has drug => (
    is        => 'rw',
    predicate => '_has_drug',
    json_ld   => 'drug',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TherapeuticProcedure - A medical procedure intended primarily for therapeutic purposes

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A medical procedure intended primarily for therapeutic purposes, aimed at
improving a health condition.

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

=head2 C<_has_adverse_outcome>

A predicate for the L</adverse_outcome> attribute.

=head2 C<dose_schedule>

C<doseSchedule>

A dosing schedule for the drug for a given population, either observed,
recommended, or maximum dose based on the type used.

A dose_schedule should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DoseSchedule']>

=back

=head2 C<_has_dose_schedule>

A predicate for the L</dose_schedule> attribute.

=head2 C<drug>

Specifying a drug or medicine used in a medication procedure

A drug should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Drug']>

=back

=head2 C<_has_drug>

A predicate for the L</drug> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalProcedure>

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
