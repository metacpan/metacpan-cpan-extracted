use utf8;

package SemanticWeb::Schema::MedicalRiskCalculator;

# ABSTRACT: A complex mathematical calculation requiring an online calculator

use Moo;

extends qw/ SemanticWeb::Schema::MedicalRiskEstimator /;


use MooX::JSON_LD 'MedicalRiskCalculator';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalRiskCalculator - A complex mathematical calculation requiring an online calculator

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A complex mathematical calculation requiring an online calculator, used to
assess prognosis. Note: use the url property of Thing to record any URLs
for online calculators.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalRiskEstimator>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
