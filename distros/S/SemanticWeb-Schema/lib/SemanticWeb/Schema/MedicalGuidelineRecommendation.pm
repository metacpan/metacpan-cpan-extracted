use utf8;

package SemanticWeb::Schema::MedicalGuidelineRecommendation;

# ABSTRACT: A guideline recommendation that is regarded as efficacious and where quality of the data supporting the recommendation is sound.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalGuideline /;


use MooX::JSON_LD 'MedicalGuidelineRecommendation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


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

version v3.8.1

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
