use utf8;

package SemanticWeb::Schema::MedicalScholarlyArticle;

# ABSTRACT: A scholarly article in the medical domain.

use Moo;

extends qw/ SemanticWeb::Schema::ScholarlyArticle /;


use MooX::JSON_LD 'MedicalScholarlyArticle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has publication_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'publicationType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalScholarlyArticle - A scholarly article in the medical domain.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A scholarly article in the medical domain.

=head1 ATTRIBUTES

=head2 C<publication_type>

C<publicationType>

=for html The type of the medical article, taken from the US NLM MeSH publication
type catalog. See also <a
href="http://www.nlm.nih.gov/mesh/pubtypes.html">MeSH documentation</a>.

A publication_type should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::ScholarlyArticle>

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
