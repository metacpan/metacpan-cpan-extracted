use utf8;

package SemanticWeb::Schema::ProgramMembership;

# ABSTRACT: Used to describe membership in a loyalty programs (e

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'ProgramMembership';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.1';


has hosting_organization => (
    is        => 'rw',
    predicate => '_has_hosting_organization',
    json_ld   => 'hostingOrganization',
);



has member => (
    is        => 'rw',
    predicate => '_has_member',
    json_ld   => 'member',
);



has members => (
    is        => 'rw',
    predicate => '_has_members',
    json_ld   => 'members',
);



has membership_number => (
    is        => 'rw',
    predicate => '_has_membership_number',
    json_ld   => 'membershipNumber',
);



has membership_points_earned => (
    is        => 'rw',
    predicate => '_has_membership_points_earned',
    json_ld   => 'membershipPointsEarned',
);



has program_name => (
    is        => 'rw',
    predicate => '_has_program_name',
    json_ld   => 'programName',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ProgramMembership - Used to describe membership in a loyalty programs (e

=head1 VERSION

version v6.0.1

=head1 DESCRIPTION

Used to describe membership in a loyalty programs (e.g. "StarAliance"),
traveler clubs (e.g. "AAA"), purchase clubs ("Safeway Club"), etc.

=head1 ATTRIBUTES

=head2 C<hosting_organization>

C<hostingOrganization>

The organization (airline, travelers' club, etc.) the membership is made
with.

A hosting_organization should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_hosting_organization>

A predicate for the L</hosting_organization> attribute.

=head2 C<member>

A member of an Organization or a ProgramMembership. Organizations can be
members of organizations; ProgramMembership is typically for individuals.

A member should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_member>

A predicate for the L</member> attribute.

=head2 C<members>

A member of this organization.

A members should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_members>

A predicate for the L</members> attribute.

=head2 C<membership_number>

C<membershipNumber>

A unique identifier for the membership.

A membership_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_membership_number>

A predicate for the L</membership_number> attribute.

=head2 C<membership_points_earned>

C<membershipPointsEarned>

The number of membership points earned by the member. If necessary, the
unitText can be used to express the units the points are issued in. (e.g.
stars, miles, etc.)

A membership_points_earned should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<_has_membership_points_earned>

A predicate for the L</membership_points_earned> attribute.

=head2 C<program_name>

C<programName>

The program providing the membership.

A program_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_program_name>

A predicate for the L</program_name> attribute.

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
