use utf8;

package SemanticWeb::Schema::HealthPlanNetwork;

# ABSTRACT: A US-style health insurance plan network.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'HealthPlanNetwork';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has health_plan_cost_sharing => (
    is        => 'rw',
    predicate => '_has_health_plan_cost_sharing',
    json_ld   => 'healthPlanCostSharing',
);



has health_plan_network_id => (
    is        => 'rw',
    predicate => '_has_health_plan_network_id',
    json_ld   => 'healthPlanNetworkId',
);



has health_plan_network_tier => (
    is        => 'rw',
    predicate => '_has_health_plan_network_tier',
    json_ld   => 'healthPlanNetworkTier',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HealthPlanNetwork - A US-style health insurance plan network.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A US-style health insurance plan network.

=head1 ATTRIBUTES

=head2 C<health_plan_cost_sharing>

C<healthPlanCostSharing>

Whether The costs to the patient for services under this network or
formulary.

A health_plan_cost_sharing should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_health_plan_cost_sharing>

A predicate for the L</health_plan_cost_sharing> attribute.

=head2 C<health_plan_network_id>

C<healthPlanNetworkId>

Name or unique ID of network. (Networks are often reused across different
insurance plans).

A health_plan_network_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_health_plan_network_id>

A predicate for the L</health_plan_network_id> attribute.

=head2 C<health_plan_network_tier>

C<healthPlanNetworkTier>

The tier(s) for this network.

A health_plan_network_tier should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_health_plan_network_tier>

A predicate for the L</health_plan_network_tier> attribute.

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
