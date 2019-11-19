use utf8;

package SemanticWeb::Schema::EducationalOccupationalProgram;

# ABSTRACT: A program offered by an institution which determines the learning progress to achieve an outcome

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'EducationalOccupationalProgram';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has educational_credential_awarded => (
    is        => 'rw',
    predicate => '_has_educational_credential_awarded',
    json_ld   => 'educationalCredentialAwarded',
);



has occupational_credential_awarded => (
    is        => 'rw',
    predicate => '_has_occupational_credential_awarded',
    json_ld   => 'occupationalCredentialAwarded',
);



has offers => (
    is        => 'rw',
    predicate => '_has_offers',
    json_ld   => 'offers',
);



has program_prerequisites => (
    is        => 'rw',
    predicate => '_has_program_prerequisites',
    json_ld   => 'programPrerequisites',
);



has provider => (
    is        => 'rw',
    predicate => '_has_provider',
    json_ld   => 'provider',
);



has salary_upon_completion => (
    is        => 'rw',
    predicate => '_has_salary_upon_completion',
    json_ld   => 'salaryUponCompletion',
);



has time_to_complete => (
    is        => 'rw',
    predicate => '_has_time_to_complete',
    json_ld   => 'timeToComplete',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EducationalOccupationalProgram - A program offered by an institution which determines the learning progress to achieve an outcome

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

A program offered by an institution which determines the learning progress
to achieve an outcome, usually a credential like a degree or certificate.
This would define a discrete set of opportunities (e.g., job, courses) that
together constitute a program with a clear start, end, set of requirements,
and transition to a new occupational opportunity (e.g., a job), or
sometimes a higher educational opportunity (e.g., an advanced degree).

=head1 ATTRIBUTES

=head2 C<educational_credential_awarded>

C<educationalCredentialAwarded>

A description of the qualification, award, certificate, diploma or other
educational credential awarded as a consequence of successful completion of
this course or program.

A educational_credential_awarded should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EducationalOccupationalCredential']>

=item C<Str>

=back

=head2 C<_has_educational_credential_awarded>

A predicate for the L</educational_credential_awarded> attribute.

=head2 C<occupational_credential_awarded>

C<occupationalCredentialAwarded>

A description of the qualification, award, certificate, diploma or other
occupational credential awarded as a consequence of successful completion
of this course or program.

A occupational_credential_awarded should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EducationalOccupationalCredential']>

=item C<Str>

=back

=head2 C<_has_occupational_credential_awarded>

A predicate for the L</occupational_credential_awarded> attribute.

=head2 C<offers>

An offer to provide this item&#x2014;for example, an offer to sell a
product, rent the DVD of a movie, perform a service, or give away tickets
to an event.

A offers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<_has_offers>

A predicate for the L</offers> attribute.

=head2 C<program_prerequisites>

C<programPrerequisites>

Prerequisites for enrolling in the program.

A program_prerequisites should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AlignmentObject']>

=item C<InstanceOf['SemanticWeb::Schema::Course']>

=item C<InstanceOf['SemanticWeb::Schema::EducationalOccupationalCredential']>

=item C<Str>

=back

=head2 C<_has_program_prerequisites>

A predicate for the L</program_prerequisites> attribute.

=head2 C<provider>

The service provider, service operator, or service performer; the goods
producer. Another party (a seller) may offer those services or goods on
behalf of the provider. A provider may also serve as the seller.

A provider should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_provider>

A predicate for the L</provider> attribute.

=head2 C<salary_upon_completion>

C<salaryUponCompletion>

The expected salary upon completing the training.

A salary_upon_completion should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmountDistribution']>

=back

=head2 C<_has_salary_upon_completion>

A predicate for the L</salary_upon_completion> attribute.

=head2 C<time_to_complete>

C<timeToComplete>

The expected length of time to complete the program if attending full-time.

A time_to_complete should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_time_to_complete>

A predicate for the L</time_to_complete> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

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
