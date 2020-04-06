use utf8;

package SemanticWeb::Schema::HealthPlanCostSharingSpecification;

# ABSTRACT: A description of costs to the patient under a given network or formulary.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'HealthPlanCostSharingSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has health_plan_coinsurance_option => (
    is        => 'rw',
    predicate => '_has_health_plan_coinsurance_option',
    json_ld   => 'healthPlanCoinsuranceOption',
);



has health_plan_coinsurance_rate => (
    is        => 'rw',
    predicate => '_has_health_plan_coinsurance_rate',
    json_ld   => 'healthPlanCoinsuranceRate',
);



has health_plan_copay => (
    is        => 'rw',
    predicate => '_has_health_plan_copay',
    json_ld   => 'healthPlanCopay',
);



has health_plan_copay_option => (
    is        => 'rw',
    predicate => '_has_health_plan_copay_option',
    json_ld   => 'healthPlanCopayOption',
);



has health_plan_pharmacy_category => (
    is        => 'rw',
    predicate => '_has_health_plan_pharmacy_category',
    json_ld   => 'healthPlanPharmacyCategory',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HealthPlanCostSharingSpecification - A description of costs to the patient under a given network or formulary.

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

A description of costs to the patient under a given network or formulary.

=head1 ATTRIBUTES

=head2 C<health_plan_coinsurance_option>

C<healthPlanCoinsuranceOption>

Whether the coinsurance applies before or after deductible, etc. TODO: Is
this a closed set?

A health_plan_coinsurance_option should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_health_plan_coinsurance_option>

A predicate for the L</health_plan_coinsurance_option> attribute.

=head2 C<health_plan_coinsurance_rate>

C<healthPlanCoinsuranceRate>

Whether The rate of coinsurance expressed as a number between 0.0 and 1.0.

A health_plan_coinsurance_rate should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_health_plan_coinsurance_rate>

A predicate for the L</health_plan_coinsurance_rate> attribute.

=head2 C<health_plan_copay>

C<healthPlanCopay>

Whether The copay amount.

A health_plan_copay should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PriceSpecification']>

=back

=head2 C<_has_health_plan_copay>

A predicate for the L</health_plan_copay> attribute.

=head2 C<health_plan_copay_option>

C<healthPlanCopayOption>

Whether the copay is before or after deductible, etc. TODO: Is this a
closed set?

A health_plan_copay_option should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_health_plan_copay_option>

A predicate for the L</health_plan_copay_option> attribute.

=head2 C<health_plan_pharmacy_category>

C<healthPlanPharmacyCategory>

The category or type of pharmacy associated with this cost sharing.

A health_plan_pharmacy_category should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_health_plan_pharmacy_category>

A predicate for the L</health_plan_pharmacy_category> attribute.

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
