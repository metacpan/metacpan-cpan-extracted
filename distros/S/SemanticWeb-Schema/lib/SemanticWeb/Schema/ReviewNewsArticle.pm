use utf8;

package SemanticWeb::Schema::ReviewNewsArticle;

# ABSTRACT: A NewsArticle and CriticReview providing a professional critic's assessment of a service

use Moo;

extends qw/ SemanticWeb::Schema::CriticReview SemanticWeb::Schema::NewsArticle /;


use MooX::JSON_LD 'ReviewNewsArticle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ReviewNewsArticle - A NewsArticle and CriticReview providing a professional critic's assessment of a service

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

=for html <p>A <a class="localLink"
href="http://schema.org/NewsArticle">NewsArticle</a> and <a
class="localLink" href="http://schema.org/CriticReview">CriticReview</a>
providing a professional critic's assessment of a service, product,
performance, or artistic or literary work.<p>

=head1 SEE ALSO

L<SemanticWeb::Schema::NewsArticle>

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
