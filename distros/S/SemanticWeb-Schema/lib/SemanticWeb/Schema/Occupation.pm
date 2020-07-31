use utf8;

package SemanticWeb::Schema::Occupation;

# ABSTRACT: A profession

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Occupation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has education_requirements => (
    is        => 'rw',
    predicate => '_has_education_requirements',
    json_ld   => 'educationRequirements',
);



has estimated_salary => (
    is        => 'rw',
    predicate => '_has_estimated_salary',
    json_ld   => 'estimatedSalary',
);



has experience_requirements => (
    is        => 'rw',
    predicate => '_has_experience_requirements',
    json_ld   => 'experienceRequirements',
);



has occupation_location => (
    is        => 'rw',
    predicate => '_has_occupation_location',
    json_ld   => 'occupationLocation',
);



has occupational_category => (
    is        => 'rw',
    predicate => '_has_occupational_category',
    json_ld   => 'occupationalCategory',
);



has qualifications => (
    is        => 'rw',
    predicate => '_has_qualifications',
    json_ld   => 'qualifications',
);



has responsibilities => (
    is        => 'rw',
    predicate => '_has_responsibilities',
    json_ld   => 'responsibilities',
);



has skills => (
    is        => 'rw',
    predicate => '_has_skills',
    json_ld   => 'skills',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Occupation - A profession

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A profession, may involve prolonged training and/or a formal qualification.

=head1 ATTRIBUTES

=head2 C<education_requirements>

C<educationRequirements>

Educational background needed for the position or Occupation.

A education_requirements should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EducationalOccupationalCredential']>

=item C<Str>

=back

=head2 C<_has_education_requirements>

A predicate for the L</education_requirements> attribute.

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

=head2 C<_has_estimated_salary>

A predicate for the L</estimated_salary> attribute.

=head2 C<experience_requirements>

C<experienceRequirements>

Description of skills and experience needed for the position or Occupation.

A experience_requirements should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_experience_requirements>

A predicate for the L</experience_requirements> attribute.

=head2 C<occupation_location>

C<occupationLocation>

The region/country for which this occupational description is appropriate.
Note that educational requirements and qualifications can vary between
jurisdictions.

A occupation_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=back

=head2 C<_has_occupation_location>

A predicate for the L</occupation_location> attribute.

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

=head2 C<qualifications>

Specific qualifications required for this role or Occupation.

A qualifications should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EducationalOccupationalCredential']>

=item C<Str>

=back

=head2 C<_has_qualifications>

A predicate for the L</qualifications> attribute.

=head2 C<responsibilities>

Responsibilities associated with this role or Occupation.

A responsibilities should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_responsibilities>

A predicate for the L</responsibilities> attribute.

=head2 C<skills>

A statement of knowledge, skill, ability, task or any other assertion
expressing a competency that is desired or required to fulfill this role or
to work in this occupation.

A skills should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTerm']>

=item C<Str>

=back

=head2 C<_has_skills>

A predicate for the L</skills> attribute.

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
