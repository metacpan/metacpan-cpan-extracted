use utf8;

package SemanticWeb::Schema::OpinionNewsArticle;

# ABSTRACT: An <a class="localLink" href="http://schema

use Moo;

extends qw/ SemanticWeb::Schema::NewsArticle /;


use MooX::JSON_LD 'OpinionNewsArticle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::OpinionNewsArticle - An <a class="localLink" href="http://schema

=head1 VERSION

version v3.9.0

=head1 DESCRIPTION

=for html An <a class="localLink"
href="http://schema.org/OpinionNewsArticle">OpinionNewsArticle</a> is a <a
class="localLink" href="http://schema.org/NewsArticle">NewsArticle</a> that
primarily expresses opinions rather than journalistic reporting of news and
events. For example, a <a class="localLink"
href="http://schema.org/NewsArticle">NewsArticle</a> consisting of a column
or <a class="localLink" href="http://schema.org/Blog">Blog</a>/<a
class="localLink" href="http://schema.org/BlogPosting">BlogPosting</a>
entry in the Opinions section of a news publication.

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
