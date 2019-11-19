use utf8;

package SemanticWeb::Schema::ActionAccessSpecification;

# ABSTRACT: A set of requirements that a must be fulfilled in order to perform an Action.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'ActionAccessSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has availability_ends => (
    is        => 'rw',
    predicate => '_has_availability_ends',
    json_ld   => 'availabilityEnds',
);



has availability_starts => (
    is        => 'rw',
    predicate => '_has_availability_starts',
    json_ld   => 'availabilityStarts',
);



has category => (
    is        => 'rw',
    predicate => '_has_category',
    json_ld   => 'category',
);



has eligible_region => (
    is        => 'rw',
    predicate => '_has_eligible_region',
    json_ld   => 'eligibleRegion',
);



has expects_acceptance_of => (
    is        => 'rw',
    predicate => '_has_expects_acceptance_of',
    json_ld   => 'expectsAcceptanceOf',
);



has ineligible_region => (
    is        => 'rw',
    predicate => '_has_ineligible_region',
    json_ld   => 'ineligibleRegion',
);



has requires_subscription => (
    is        => 'rw',
    predicate => '_has_requires_subscription',
    json_ld   => 'requiresSubscription',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ActionAccessSpecification - A set of requirements that a must be fulfilled in order to perform an Action.

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

A set of requirements that a must be fulfilled in order to perform an
Action.

=head1 ATTRIBUTES

=head2 C<availability_ends>

C<availabilityEnds>

The end of the availability of the product or service included in the
offer.

A availability_ends should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_availability_ends>

A predicate for the L</availability_ends> attribute.

=head2 C<availability_starts>

C<availabilityStarts>

The beginning of the availability of the product or service included in the
offer.

A availability_starts should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_availability_starts>

A predicate for the L</availability_starts> attribute.

=head2 C<category>

A category for the item. Greater signs or slashes can be used to informally
indicate a category hierarchy.

A category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PhysicalActivityCategory']>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head2 C<_has_category>

A predicate for the L</category> attribute.

=head2 C<eligible_region>

C<eligibleRegion>

=for html <p>The ISO 3166-1 (ISO 3166-1 alpha-2) or ISO 3166-2 code, the place, or
the GeoShape for the geo-political region(s) for which the offer or
delivery charge specification is valid.<br/><br/> See also <a
class="localLink"
href="http://schema.org/ineligibleRegion">ineligibleRegion</a>.<p>

A eligible_region should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<_has_eligible_region>

A predicate for the L</eligible_region> attribute.

=head2 C<expects_acceptance_of>

C<expectsAcceptanceOf>

An Offer which must be accepted before the user can perform the Action. For
example, the user may need to buy a movie before being able to watch it.

A expects_acceptance_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<_has_expects_acceptance_of>

A predicate for the L</expects_acceptance_of> attribute.

=head2 C<ineligible_region>

C<ineligibleRegion>

=for html <p>The ISO 3166-1 (ISO 3166-1 alpha-2) or ISO 3166-2 code, the place, or
the GeoShape for the geo-political region(s) for which the offer or
delivery charge specification is not valid, e.g. a region where the
transaction is not allowed.<br/><br/> See also <a class="localLink"
href="http://schema.org/eligibleRegion">eligibleRegion</a>.<p>

A ineligible_region should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<Str>

=back

=head2 C<_has_ineligible_region>

A predicate for the L</ineligible_region> attribute.

=head2 C<requires_subscription>

C<requiresSubscription>

=for html <p>Indicates if use of the media require a subscription (either paid or
free). Allowed values are <code>true</code> or <code>false</code> (note
that an earlier version had 'yes', 'no').<p>

A requires_subscription should be one of the following types:

=over

=item C<Bool>

=item C<InstanceOf['SemanticWeb::Schema::MediaSubscription']>

=back

=head2 C<_has_requires_subscription>

A predicate for the L</requires_subscription> attribute.

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
