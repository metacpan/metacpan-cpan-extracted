use utf8;

package SemanticWeb::Schema::ActionAccessSpecification;

# ABSTRACT: A set of requirements that a must be fulfilled in order to perform an Action.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'ActionAccessSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has availability_ends => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availabilityEnds',
);



has availability_starts => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availabilityStarts',
);



has category => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'category',
);



has eligible_region => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'eligibleRegion',
);



has expects_acceptance_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'expectsAcceptanceOf',
);



has requires_subscription => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'requiresSubscription',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ActionAccessSpecification - A set of requirements that a must be fulfilled in order to perform an Action.

=head1 VERSION

version v3.5.0

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

=head2 C<availability_starts>

C<availabilityStarts>

The beginning of the availability of the product or service included in the
offer.

A availability_starts should be one of the following types:

=over

=item C<Str>

=back

=head2 C<category>

A category for the item. Greater signs or slashes can be used to informally
indicate a category hierarchy.

A category should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::PhysicalActivityCategory']>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<eligible_region>

C<eligibleRegion>

=for html The ISO 3166-1 (ISO 3166-1 alpha-2) or ISO 3166-2 code, the place, or the
GeoShape for the geo-political region(s) for which the offer or delivery
charge specification is valid.<br/><br/> See also <a class="localLink"
href="http://schema.org/ineligibleRegion">ineligibleRegion</a>.

A eligible_region should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<InstanceOf['SemanticWeb::Schema::GeoShape']>

=back

=head2 C<expects_acceptance_of>

C<expectsAcceptanceOf>

An Offer which must be accepted before the user can perform the Action. For
example, the user may need to buy a movie before being able to watch it.

A expects_acceptance_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<requires_subscription>

C<requiresSubscription>

=for html Indicates if use of the media require a subscription (either paid or free).
Allowed values are <code>true</code> or <code>false</code> (note that an
earlier version had 'yes', 'no').

A requires_subscription should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MediaSubscription']>

=item C<Bool>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
