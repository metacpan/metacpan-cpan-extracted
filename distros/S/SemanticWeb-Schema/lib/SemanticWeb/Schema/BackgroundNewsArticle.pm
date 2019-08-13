use utf8;

package SemanticWeb::Schema::BackgroundNewsArticle;

# ABSTRACT: A <a class="localLink" href="http://schema

use Moo;

extends qw/ SemanticWeb::Schema::NewsArticle /;


use MooX::JSON_LD 'BackgroundNewsArticle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BackgroundNewsArticle - A <a class="localLink" href="http://schema

=head1 VERSION

version v3.9.0

=head1 DESCRIPTION

=for html A <a class="localLink" href="http://schema.org/NewsArticle">NewsArticle</a>
providing historical context, definition and detail on a specific topic
(aka "explainer" or "backgrounder"). For example, an in-depth article or
frequently-asked-questions (<a
href="https://en.wikipedia.org/wiki/FAQ">FAQ</a>) document on topics such
as Climate Change or the European Union. Other kinds of background material
from a non-news setting are often described using <a class="localLink"
href="http://schema.org/Book">Book</a> or <a class="localLink"
href="http://schema.org/Article">Article</a>, in particular <a
class="localLink"
href="http://schema.org/ScholarlyArticle">ScholarlyArticle</a>. See also <a
class="localLink" href="http://schema.org/NewsArticle">NewsArticle</a> for
related vocabulary from a learning/education perspective.

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
