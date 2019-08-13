use utf8;

package SemanticWeb::Schema::ReportageNewsArticle;

# ABSTRACT: The <a class="localLink" href="http://schema

use Moo;

extends qw/ SemanticWeb::Schema::NewsArticle /;


use MooX::JSON_LD 'ReportageNewsArticle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ReportageNewsArticle - The <a class="localLink" href="http://schema

=head1 VERSION

version v3.9.0

=head1 DESCRIPTION

=for html The <a class="localLink"
href="http://schema.org/ReportageNewsArticle">ReportageNewsArticle</a> type
is a subtype of <a class="localLink"
href="http://schema.org/NewsArticle">NewsArticle</a> representing news
articles which are the result of journalistic news reporting
conventions.<br/><br/> In practice many news publishers produce a wide
variety of article types, many of which might be considered a <a
class="localLink" href="http://schema.org/NewsArticle">NewsArticle</a> but
not a <a class="localLink"
href="http://schema.org/ReportageNewsArticle">ReportageNewsArticle</a>. For
example, opinion pieces, reviews, analysis, sponsored or satirical
articles, or articles that combine several of these elements.<br/><br/> The
<a class="localLink"
href="http://schema.org/ReportageNewsArticle">ReportageNewsArticle</a> type
is based on a stricter ideal for "news" as a work of journalism, with
articles based on factual information either observed or verified by the
author, or reported and verified from knowledgeable sources. This often
includes perspectives from multiple viewpoints on a particular issue
(distinguishing news reports from public relations or propaganda). News
reports in the <a class="localLink"
href="http://schema.org/ReportageNewsArticle">ReportageNewsArticle</a>
sense de-emphasize the opinion of the author, with commentary and value
judgements typically expressed elsewhere.<br/><br/> A <a class="localLink"
href="http://schema.org/ReportageNewsArticle">ReportageNewsArticle</a>
which goes deeper into analysis can also be marked with an additional type
of <a class="localLink"
href="http://schema.org/AnalysisNewsArticle">AnalysisNewsArticle</a>.

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
