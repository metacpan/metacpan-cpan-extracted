use utf8;

package SemanticWeb::Schema::BusinessAudience;

# ABSTRACT: A set of characteristics belonging to businesses

use Moo;

extends qw/ SemanticWeb::Schema::Audience /;


use MooX::JSON_LD 'BusinessAudience';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has number_of_employees => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfEmployees',
);



has yearly_revenue => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'yearlyRevenue',
);



has years_in_operation => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'yearsInOperation',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BusinessAudience - A set of characteristics belonging to businesses

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A set of characteristics belonging to businesses, e.g. who compose an
item's target audience.

=head1 ATTRIBUTES

=head2 C<number_of_employees>

C<numberOfEmployees>

The number of employees in an organization e.g. business.

A number_of_employees should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<yearly_revenue>

C<yearlyRevenue>

The size of the business in annual revenue.

A yearly_revenue should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<years_in_operation>

C<yearsInOperation>

The age of the business.

A years_in_operation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Audience>

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
