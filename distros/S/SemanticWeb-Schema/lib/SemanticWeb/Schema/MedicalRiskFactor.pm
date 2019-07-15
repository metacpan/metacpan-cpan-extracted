use utf8;

package SemanticWeb::Schema::MedicalRiskFactor;

# ABSTRACT: A risk factor is anything that increases a person's likelihood of developing or contracting a disease

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalRiskFactor';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has increases_risk_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'increasesRiskOf',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalRiskFactor - A risk factor is anything that increases a person's likelihood of developing or contracting a disease

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A risk factor is anything that increases a person's likelihood of
developing or contracting a disease, medical condition, or complication.

=head1 ATTRIBUTES

=head2 C<increases_risk_of>

C<increasesRiskOf>

The condition, complication, etc. influenced by this factor.

A increases_risk_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEntity']>

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
