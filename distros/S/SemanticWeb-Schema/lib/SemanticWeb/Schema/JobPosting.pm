use utf8;

package SemanticWeb::Schema::JobPosting;

# ABSTRACT: A listing that describes a job opening in a certain organization.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'JobPosting';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has base_salary => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'baseSalary',
);



has benefits => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'benefits',
);



has date_posted => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'datePosted',
);



has employment_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'employmentType',
);



has estimated_salary => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'estimatedSalary',
);



has experience_requirements => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'experienceRequirements',
);



has hiring_organization => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hiringOrganization',
);



has incentive_compensation => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'incentiveCompensation',
);



has incentives => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'incentives',
);



has industry => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'industry',
);



has job_benefits => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'jobBenefits',
);



has job_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'jobLocation',
);



has occupational_category => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'occupationalCategory',
);



has relevant_occupation => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'relevantOccupation',
);



has responsibilities => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'responsibilities',
);



has salary_currency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'salaryCurrency',
);



has skills => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'skills',
);



has special_commitments => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'specialCommitments',
);



has title => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'title',
);



has valid_through => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'validThrough',
);



has work_hours => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'workHours',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::JobPosting - A listing that describes a job opening in a certain organization.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A listing that describes a job opening in a certain organization.

=head1 ATTRIBUTES

=head2 C<base_salary>

C<baseSalary>

The base salary of the job or of an employee in an EmployeeRole.

A base_salary should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<InstanceOf['SemanticWeb::Schema::PriceSpecification']>

=item C<Num>

=back

=head2 C<benefits>

Description of benefits associated with the job.

A benefits should be one of the following types:

=over

=item C<Str>

=back

=head2 C<date_posted>

C<datePosted>

Publication date for the job posting.

A date_posted should be one of the following types:

=over

=item C<Str>

=back

=head2 C<employment_type>

C<employmentType>

Type of employment (e.g. full-time, part-time, contract, temporary,
seasonal, internship).

A employment_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<estimated_salary>

C<estimatedSalary>

An estimated salary for a job posting or occupation, based on a variety of
variables including, but not limited to industry, job title, and location.
Estimated salaries are often computed by outside organizations rather than
the hiring organization, who may not have committed to the estimated value.

A estimated_salary should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmountDistribution']>

=item C<Num>

=back

=head2 C<experience_requirements>

C<experienceRequirements>

Description of skills and experience needed for the position or Occupation.

A experience_requirements should be one of the following types:

=over

=item C<Str>

=back

=head2 C<hiring_organization>

C<hiringOrganization>

Organization offering the job position.

A hiring_organization should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<incentive_compensation>

C<incentiveCompensation>

Description of bonus and commission compensation aspects of the job.

A incentive_compensation should be one of the following types:

=over

=item C<Str>

=back

=head2 C<incentives>

Description of bonus and commission compensation aspects of the job.

A incentives should be one of the following types:

=over

=item C<Str>

=back

=head2 C<industry>

The industry associated with the job position.

A industry should be one of the following types:

=over

=item C<Str>

=back

=head2 C<job_benefits>

C<jobBenefits>

Description of benefits associated with the job.

A job_benefits should be one of the following types:

=over

=item C<Str>

=back

=head2 C<job_location>

C<jobLocation>

A (typically single) geographic location associated with the job position.

A job_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<occupational_category>

C<occupationalCategory>

=for html A category describing the job, preferably using a term from a taxonomy such
as <a href="http://www.onetcenter.org/taxonomy.html">BLS O*NET-SOC</a>, <a
href="https://www.ilo.org/public/english/bureau/stat/isco/isco08/">ISCO-08<
/a> or similar, with the property repeated for each applicable value.
Ideally the taxonomy should be identified, and both the textual label and
formal code for the category should be provided.<br/><br/> Note: for
historical reasons, any textual label and formal code provided as a literal
may be assumed to be from O*NET-SOC.

A occupational_category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CategoryCode']>

=item C<Str>

=back

=head2 C<relevant_occupation>

C<relevantOccupation>

The Occupation for the JobPosting.

A relevant_occupation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Occupation']>

=back

=head2 C<responsibilities>

Responsibilities associated with this role or Occupation.

A responsibilities should be one of the following types:

=over

=item C<Str>

=back

=head2 C<salary_currency>

C<salaryCurrency>

=for html The currency (coded using <a
href="http://en.wikipedia.org/wiki/ISO_4217">ISO 4217</a> ) used for the
main salary information in this job posting or for this employee.

A salary_currency should be one of the following types:

=over

=item C<Str>

=back

=head2 C<skills>

Skills required to fulfill this role or in this Occupation.

A skills should be one of the following types:

=over

=item C<Str>

=back

=head2 C<special_commitments>

C<specialCommitments>

Any special commitments associated with this job posting. Valid entries
include VeteranCommit, MilitarySpouseCommit, etc.

A special_commitments should be one of the following types:

=over

=item C<Str>

=back

=head2 C<title>

The title of the job.

A title should be one of the following types:

=over

=item C<Str>

=back

=head2 C<valid_through>

C<validThrough>

The date after when the item is not valid. For example the end of an offer,
salary period, or a period of opening hours.

A valid_through should be one of the following types:

=over

=item C<Str>

=back

=head2 C<work_hours>

C<workHours>

The typical working hours for this job (e.g. 1st shift, night shift,
8am-5pm).

A work_hours should be one of the following types:

=over

=item C<Str>

=back

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
