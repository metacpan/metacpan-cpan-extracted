package SemanticWeb::Schema::Article;

# ABSTRACT: An article

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Article';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has article_body => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'articleBody',
);



has article_section => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'articleSection',
);



has page_end => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'pageEnd',
);



has page_start => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'pageStart',
);



has pagination => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'pagination',
);



has word_count => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'wordCount',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Article - An article

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html An article, such as a news article or piece of investigative report.
Newspapers and magazines have articles of many different types and this is
intended to cover them all.</p> <p>See also <a
href="http://blog.schema.org/2014/09/schemaorg-support-for-bibliographic_2.
html">blog post</a>.

=head1 ATTRIBUTES

=head2 C<article_body>

C<articleBody>

The actual body of the article.

A article_body should be one of the following types:

=over

=item C<Str>

=back

=head2 C<article_section>

C<articleSection>

Articles may belong to one or more 'sections' in a magazine or newspaper,
such as Sports, Lifestyle, etc.

A article_section should be one of the following types:

=over

=item C<Str>

=back

=head2 C<page_end>

C<pageEnd>

The page on which the work ends; for example "138" or "xvi".

A page_end should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<page_start>

C<pageStart>

The page on which the work starts; for example "135" or "xiii".

A page_start should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<Str>

=back

=head2 C<pagination>

Any description of pages that is not separated into pageStart and pageEnd;
for example, "1-6, 9, 55" or "10-12, 46-49".

A pagination should be one of the following types:

=over

=item C<Str>

=back

=head2 C<word_count>

C<wordCount>

The number of words in the text of the Article.

A word_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
