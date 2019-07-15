use utf8;

package SemanticWeb::Schema::NewsArticle;

# ABSTRACT: A NewsArticle is an article whose content reports news

use Moo;

extends qw/ SemanticWeb::Schema::Article /;


use MooX::JSON_LD 'NewsArticle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has dateline => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'dateline',
);



has print_column => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'printColumn',
);



has print_edition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'printEdition',
);



has print_page => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'printPage',
);



has print_section => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'printSection',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::NewsArticle - A NewsArticle is an article whose content reports news

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A NewsArticle is an article whose content reports news, or provides
background context and supporting materials for understanding the
news.<br/><br/> A more detailed overview of <a
href="/docs/news.html">schema.org News markup</a> is also available.

=head1 ATTRIBUTES

=head2 C<dateline>

=for html A <a href="https://en.wikipedia.org/wiki/Dateline">dateline</a> is a brief
piece of text included in news articles that describes where and when the
story was written or filed though the date is often omitted. Sometimes only
a placename is provided.<br/><br/> Structured representations of
dateline-related information can also be expressed more explicitly using <a
class="localLink"
href="http://schema.org/locationCreated">locationCreated</a> (which
represents where a work was created e.g. where a news report was written).
For location depicted or described in the content, use <a class="localLink"
href="http://schema.org/contentLocation">contentLocation</a>.<br/><br/>
Dateline summaries are oriented more towards human readers than towards
automated processing, and can vary substantially. Some examples: "BEIRUT,
Lebanon, June 2.", "Paris, France", "December 19, 2017 11:43AM Reporting
from Washington", "Beijing/Moscow", "QUEZON CITY, Philippines".

A dateline should be one of the following types:

=over

=item C<Str>

=back

=head2 C<print_column>

C<printColumn>

The number of the column in which the NewsArticle appears in the print
edition.

A print_column should be one of the following types:

=over

=item C<Str>

=back

=head2 C<print_edition>

C<printEdition>

The edition of the print product in which the NewsArticle appears.

A print_edition should be one of the following types:

=over

=item C<Str>

=back

=head2 C<print_page>

C<printPage>

If this NewsArticle appears in print, this field indicates the name of the
page on which the article is found. Please note that this field is intended
for the exact page name (e.g. A5, B18).

A print_page should be one of the following types:

=over

=item C<Str>

=back

=head2 C<print_section>

C<printSection>

If this NewsArticle appears in print, this field indicates the print
section in which the article appeared.

A print_section should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Article>

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
