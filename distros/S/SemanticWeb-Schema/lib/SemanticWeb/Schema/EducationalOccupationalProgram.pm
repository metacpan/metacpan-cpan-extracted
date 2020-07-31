use utf8;

package SemanticWeb::Schema::EducationalOccupationalProgram;

# ABSTRACT: A program offered by an institution which determines the learning progress to achieve an outcome

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'EducationalOccupationalProgram';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has application_deadline => (
    is        => 'rw',
    predicate => '_has_application_deadline',
    json_ld   => 'applicationDeadline',
);



has application_start_date => (
    is        => 'rw',
    predicate => '_has_application_start_date',
    json_ld   => 'applicationStartDate',
);



has day_of_week => (
    is        => 'rw',
    predicate => '_has_day_of_week',
    json_ld   => 'dayOfWeek',
);



has educational_credential_awarded => (
    is        => 'rw',
    predicate => '_has_educational_credential_awarded',
    json_ld   => 'educationalCredentialAwarded',
);



has educational_program_mode => (
    is        => 'rw',
    predicate => '_has_educational_program_mode',
    json_ld   => 'educationalProgramMode',
);



has end_date => (
    is        => 'rw',
    predicate => '_has_end_date',
    json_ld   => 'endDate',
);



has financial_aid_eligible => (
    is        => 'rw',
    predicate => '_has_financial_aid_eligible',
    json_ld   => 'financialAidEligible',
);



has maximum_enrollment => (
    is        => 'rw',
    predicate => '_has_maximum_enrollment',
    json_ld   => 'maximumEnrollment',
);



has number_of_credits => (
    is        => 'rw',
    predicate => '_has_number_of_credits',
    json_ld   => 'numberOfCredits',
);



has occupational_category => (
    is        => 'rw',
    predicate => '_has_occupational_category',
    json_ld   => 'occupationalCategory',
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



has program_type => (
    is        => 'rw',
    predicate => '_has_program_type',
    json_ld   => 'programType',
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



has start_date => (
    is        => 'rw',
    predicate => '_has_start_date',
    json_ld   => 'startDate',
);



has term_duration => (
    is        => 'rw',
    predicate => '_has_term_duration',
    json_ld   => 'termDuration',
);



has terms_per_year => (
    is        => 'rw',
    predicate => '_has_terms_per_year',
    json_ld   => 'termsPerYear',
);



has time_of_day => (
    is        => 'rw',
    predicate => '_has_time_of_day',
    json_ld   => 'timeOfDay',
);



has time_to_complete => (
    is        => 'rw',
    predicate => '_has_time_to_complete',
    json_ld   => 'timeToComplete',
);



has training_salary => (
    is        => 'rw',
    predicate => '_has_training_salary',
    json_ld   => 'trainingSalary',
);



has typical_credits_per_term => (
    is        => 'rw',
    predicate => '_has_typical_credits_per_term',
    json_ld   => 'typicalCreditsPerTerm',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EducationalOccupationalProgram - A program offered by an institution which determines the learning progress to achieve an outcome

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A program offered by an institution which determines the learning progress
to achieve an outcome, usually a credential like a degree or certificate.
This would define a discrete set of opportunities (e.g., job, courses) that
together constitute a program with a clear start, end, set of requirements,
and transition to a new occupational opportunity (e.g., a job), or
sometimes a higher educational opportunity (e.g., an advanced degree).

=head1 ATTRIBUTES

=head2 C<application_deadline>

C<applicationDeadline>

The date at which the program stops collecting applications for the next
enrollment cycle.

A application_deadline should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_application_deadline>

A predicate for the L</application_deadline> attribute.

=head2 C<application_start_date>

C<applicationStartDate>

The date at which the program begins collecting applications for the next
enrollment cycle.

A application_start_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_application_start_date>

A predicate for the L</application_start_date> attribute.

=head2 C<day_of_week>

C<dayOfWeek>

The day of the week for which these opening hours are valid.

A day_of_week should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DayOfWeek']>

=back

=head2 C<_has_day_of_week>

A predicate for the L</day_of_week> attribute.

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

=head2 C<educational_program_mode>

C<educationalProgramMode>

Similar to courseMode, The medium or means of delivery of the program as a
whole. The value may either be a text label (e.g. "online", "onsite" or
"blended"; "synchronous" or "asynchronous"; "full-time" or "part-time") or
a URL reference to a term from a controlled vocabulary (e.g.
https://ceds.ed.gov/element/001311#Asynchronous ).

A educational_program_mode should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_educational_program_mode>

A predicate for the L</educational_program_mode> attribute.

=head2 C<end_date>

C<endDate>

=for html <p>The end date and time of the item (in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>).<p>

A end_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_end_date>

A predicate for the L</end_date> attribute.

=head2 C<financial_aid_eligible>

C<financialAidEligible>

A financial aid type or program which students may use to pay for tuition
or fees associated with the program.

A financial_aid_eligible should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTerm']>

=item C<Str>

=back

=head2 C<_has_financial_aid_eligible>

A predicate for the L</financial_aid_eligible> attribute.

=head2 C<maximum_enrollment>

C<maximumEnrollment>

The maximum number of students who may be enrolled in the program.

A maximum_enrollment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_maximum_enrollment>

A predicate for the L</maximum_enrollment> attribute.

=head2 C<number_of_credits>

C<numberOfCredits>

The number of credits or units awarded by a Course or required to complete
an EducationalOccupationalProgram.

A number_of_credits should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<InstanceOf['SemanticWeb::Schema::StructuredValue']>

=back

=head2 C<_has_number_of_credits>

A predicate for the L</number_of_credits> attribute.

=head2 C<occupational_category>

C<occupationalCategory>

=for html <p>A category describing the job, preferably using a term from a taxonomy
such as <a href="http://www.onetcenter.org/taxonomy.html">BLS
O*NET-SOC</a>, <a
href="https://www.ilo.org/public/english/bureau/stat/isco/isco08/">ISCO-08<
/a> or similar, with the property repeated for each applicable value.
Ideally the taxonomy should be identified, and both the textual label and
formal code for the category should be provided.<br/><br/> Note: for
historical reasons, any textual label and formal code provided as a literal
may be assumed to be from O*NET-SOC.<p>

A occupational_category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CategoryCode']>

=item C<Str>

=back

=head2 C<_has_occupational_category>

A predicate for the L</occupational_category> attribute.

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

=for html <p>An offer to provide this item&#x2014;for example, an offer to sell a
product, rent the DVD of a movie, perform a service, or give away tickets
to an event. Use <a class="localLink"
href="http://schema.org/businessFunction">businessFunction</a> to indicate
the kind of transaction offered, i.e. sell, lease, etc. This property can
also be used to describe a <a class="localLink"
href="http://schema.org/Demand">Demand</a>. While this property is listed
as expected on a number of common types, it can be used in others. In that
case, using a second type, such as Product or a subtype of Product, can
clarify the nature of the offer.<p>

A offers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Demand']>

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

=head2 C<program_type>

C<programType>

The type of educational or occupational program. For example, classroom,
internship, alternance, etc..

A program_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTerm']>

=item C<Str>

=back

=head2 C<_has_program_type>

A predicate for the L</program_type> attribute.

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

=head2 C<start_date>

C<startDate>

=for html <p>The start date and time of the item (in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 date format</a>).<p>

A start_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_start_date>

A predicate for the L</start_date> attribute.

=head2 C<term_duration>

C<termDuration>

The amount of time in a term as defined by the institution. A term is a
length of time where students take one or more classes. Semesters and
quarters are common units for term.

A term_duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_term_duration>

A predicate for the L</term_duration> attribute.

=head2 C<terms_per_year>

C<termsPerYear>

The number of times terms of study are offered per year. Semesters and
quarters are common units for term. For example, if the student can only
take 2 semesters for the program in one year, then termsPerYear should be
2.

A terms_per_year should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_terms_per_year>

A predicate for the L</terms_per_year> attribute.

=head2 C<time_of_day>

C<timeOfDay>

The time of day the program normally runs. For example, "evenings".

A time_of_day should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_time_of_day>

A predicate for the L</time_of_day> attribute.

=head2 C<time_to_complete>

C<timeToComplete>

The expected length of time to complete the program if attending full-time.

A time_to_complete should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_time_to_complete>

A predicate for the L</time_to_complete> attribute.

=head2 C<training_salary>

C<trainingSalary>

The estimated salary earned while in the program.

A training_salary should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmountDistribution']>

=back

=head2 C<_has_training_salary>

A predicate for the L</training_salary> attribute.

=head2 C<typical_credits_per_term>

C<typicalCreditsPerTerm>

The number of credits or units a full-time student would be expected to
take in 1 term however 'term' is defined by the institution.

A typical_credits_per_term should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<InstanceOf['SemanticWeb::Schema::StructuredValue']>

=back

=head2 C<_has_typical_credits_per_term>

A predicate for the L</typical_credits_per_term> attribute.

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
