use utf8;

package SemanticWeb::Schema::MedicalGuidelineRecommendation;

# ABSTRACT: A guideline recommendation that is regarded as efficacious and where quality of the data supporting the recommendation is sound.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalGuideline /;


use MooX::JSON_LD 'MedicalGuidelineRecommendation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has recommendation_strength => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recommendationStrength',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalGuidelineRecommendation - A guideline recommendation that is regarded as efficacious and where quality of the data supporting the recommendation is sound.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A guideline recommendation that is regarded as efficacious and where
quality of the data supporting the recommendation is sound.

=head1 ATTRIBUTES

=head2 C<recommendation_strength>

C<recommendationStrength>

Strength of the guideline's recommendation (e.g. 'class I').

A recommendation_strength should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalGuideline>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
