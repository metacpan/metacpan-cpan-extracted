use utf8;

package SemanticWeb::Schema::MaximumDoseSchedule;

# ABSTRACT: The maximum dosing schedule considered safe for a drug or supplement as recommended by an authority or by the drug/supplement's manufacturer

use Moo;

extends qw/ SemanticWeb::Schema::DoseSchedule /;


use MooX::JSON_LD 'MaximumDoseSchedule';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MaximumDoseSchedule - The maximum dosing schedule considered safe for a drug or supplement as recommended by an authority or by the drug/supplement's manufacturer

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

The maximum dosing schedule considered safe for a drug or supplement as
recommended by an authority or by the drug/supplement's manufacturer.
Capture the recommending authority in the recognizingAuthority property of
MedicalEntity.

=head1 SEE ALSO

L<SemanticWeb::Schema::DoseSchedule>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
