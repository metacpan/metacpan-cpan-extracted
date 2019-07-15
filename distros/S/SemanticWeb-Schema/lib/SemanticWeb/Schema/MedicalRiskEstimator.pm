use utf8;

package SemanticWeb::Schema::MedicalRiskEstimator;

# ABSTRACT: Any rule set or interactive tool for estimating the risk of developing a complication or condition.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalRiskEstimator';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has estimates_risk_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'estimatesRiskOf',
);



has included_risk_factor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'includedRiskFactor',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalRiskEstimator - Any rule set or interactive tool for estimating the risk of developing a complication or condition.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Any rule set or interactive tool for estimating the risk of developing a
complication or condition.

=head1 ATTRIBUTES

=head2 C<estimates_risk_of>

C<estimatesRiskOf>

The condition, complication, or symptom whose risk is being estimated.

A estimates_risk_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEntity']>

=back

=head2 C<included_risk_factor>

C<includedRiskFactor>

A modifiable or non-modifiable risk factor included in the calculation,
e.g. age, coexisting condition.

A included_risk_factor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalRiskFactor']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalEntity>

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
