use utf8;

package SemanticWeb::Schema::EmployeeRole;

# ABSTRACT: A subclass of OrganizationRole used to describe employee relationships.

use Moo;

extends qw/ SemanticWeb::Schema::OrganizationRole /;


use MooX::JSON_LD 'EmployeeRole';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.0';


has base_salary => (
    is        => 'rw',
    predicate => '_has_base_salary',
    json_ld   => 'baseSalary',
);



has salary_currency => (
    is        => 'rw',
    predicate => '_has_salary_currency',
    json_ld   => 'salaryCurrency',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EmployeeRole - A subclass of OrganizationRole used to describe employee relationships.

=head1 VERSION

version v6.0.0

=head1 DESCRIPTION

A subclass of OrganizationRole used to describe employee relationships.

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

=head2 C<_has_base_salary>

A predicate for the L</base_salary> attribute.

=head2 C<salary_currency>

C<salaryCurrency>

=for html <p>The currency (coded using <a
href="http://en.wikipedia.org/wiki/ISO_4217">ISO 4217</a> ) used for the
main salary information in this job posting or for this employee.<p>

A salary_currency should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_salary_currency>

A predicate for the L</salary_currency> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::OrganizationRole>

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
