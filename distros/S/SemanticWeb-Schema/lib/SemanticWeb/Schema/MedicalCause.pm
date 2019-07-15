use utf8;

package SemanticWeb::Schema::MedicalCause;

# ABSTRACT: The causative agent(s) that are responsible for the pathophysiologic process that eventually results in a medical condition

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalCause';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has cause_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'causeOf',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalCause - The causative agent(s) that are responsible for the pathophysiologic process that eventually results in a medical condition

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

The causative agent(s) that are responsible for the pathophysiologic
process that eventually results in a medical condition, symptom or sign. In
this schema, unless otherwise specified this is meant to be the proximate
cause of the medical condition, symptom or sign. The proximate cause is
defined as the causative agent that most directly results in the medical
condition, symptom or sign. For example, the HIV virus could be considered
a cause of AIDS. Or in a diagnostic context, if a patient fell and
sustained a hip fracture and two days later sustained a pulmonary embolism
which eventuated in a cardiac arrest, the cause of the cardiac arrest (the
proximate cause) would be the pulmonary embolism and not the fall. Medical
causes can include cardiovascular, chemical, dermatologic, endocrine,
environmental, gastroenterologic, genetic, hematologic, gynecologic,
iatrogenic, infectious, musculoskeletal, neurologic, nutritional,
obstetric, oncologic, otolaryngologic, pharmacologic, psychiatric,
pulmonary, renal, rheumatologic, toxic, traumatic, or urologic causes;
medical conditions can be causes as well.

=head1 ATTRIBUTES

=head2 C<cause_of>

C<causeOf>

The condition, complication, symptom, sign, etc. caused.

A cause_of should be one of the following types:

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
