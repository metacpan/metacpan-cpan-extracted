use utf8;

package SemanticWeb::Schema::EmployeeRole;

# ABSTRACT: A subclass of OrganizationRole used to describe employee relationships.

use Moo;

extends qw/ SemanticWeb::Schema::OrganizationRole /;


use MooX::JSON_LD 'EmployeeRole';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has base_salary => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'baseSalary',
);



has salary_currency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'salaryCurrency',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EmployeeRole - A subclass of OrganizationRole used to describe employee relationships.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A subclass of OrganizationRole used to describe employee relationships.

=head1 ATTRIBUTES

=head2 C<base_salary>

C<baseSalary>

The base salary of the job or of an employee in an EmployeeRole.

A base_salary should be one of the following types:

=over

=item C<Num>

=item C<InstanceOf['SemanticWeb::Schema::PriceSpecification']>

=item C<InstanceOf['SemanticWeb::Schema::MonetaryAmount']>

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

=head1 SEE ALSO

L<SemanticWeb::Schema::OrganizationRole>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
