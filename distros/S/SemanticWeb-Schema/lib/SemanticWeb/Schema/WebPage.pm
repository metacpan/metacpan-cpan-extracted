use utf8;

package SemanticWeb::Schema::WebPage;

# ABSTRACT: A web page

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'WebPage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has breadcrumb => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'breadcrumb',
);



has last_reviewed => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'lastReviewed',
);



has main_content_of_page => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'mainContentOfPage',
);



has primary_image_of_page => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'primaryImageOfPage',
);



has related_link => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'relatedLink',
);



has reviewed_by => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'reviewedBy',
);



has significant_link => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'significantLink',
);



has significant_links => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'significantLinks',
);



has speakable => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'speakable',
);



has specialty => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'specialty',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::WebPage - A web page

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A web page. Every web page is implicitly assumed to be declared to be of
type WebPage, so the various properties about that webpage, such as
<code>breadcrumb</code> may be used. We recommend explicit declaration if
these properties are specified, but if they are found outside of an
itemscope, they will be assumed to be about the page.

=head1 ATTRIBUTES

=head2 C<breadcrumb>

A set of links that can help a user understand and navigate a website
hierarchy.

A breadcrumb should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BreadcrumbList']>

=item C<Str>

=back

=head2 C<last_reviewed>

C<lastReviewed>

Date on which the content on this web page was last reviewed for accuracy
and/or completeness.

A last_reviewed should be one of the following types:

=over

=item C<Str>

=back

=head2 C<main_content_of_page>

C<mainContentOfPage>

Indicates if this web page element is the main subject of the page.

A main_content_of_page should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::WebPageElement']>

=back

=head2 C<primary_image_of_page>

C<primaryImageOfPage>

Indicates the main image on the page.

A primary_image_of_page should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=back

=head2 C<related_link>

C<relatedLink>

A link related to this web page, for example to other related web pages.

A related_link should be one of the following types:

=over

=item C<Str>

=back

=head2 C<reviewed_by>

C<reviewedBy>

People or organizations that have reviewed the content on this web page for
accuracy and/or completeness.

A reviewed_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<significant_link>

C<significantLink>

One of the more significant URLs on the page. Typically, these are the
non-navigation links that are clicked on the most.

A significant_link should be one of the following types:

=over

=item C<Str>

=back

=head2 C<significant_links>

C<significantLinks>

The most significant URLs on the page. Typically, these are the
non-navigation links that are clicked on the most.

A significant_links should be one of the following types:

=over

=item C<Str>

=back

=head2 C<speakable>

=for html Indicates sections of a Web page that are particularly 'speakable' in the
sense of being highlighted as being especially appropriate for
text-to-speech conversion. Other sections of a page may also be usefully
spoken in particular circumstances; the 'speakable' property serves to
indicate the parts most likely to be generally useful for speech.<br/><br/>
The <em>speakable</em> property can be repeated an arbitrary number of
times, with three kinds of possible 'content-locator' values:<br/><br/> 1.)
<em>id-value</em> URL references - uses <em>id-value</em> of an element in
the page being annotated. The simplest use of <em>speakable</em> has
(potentially relative) URL values, referencing identified sections of the
document concerned.<br/><br/> 2.) CSS Selectors - addresses content in the
annotated page, eg. via class attribute. Use the <a class="localLink"
href="http://schema.org/cssSelector">cssSelector</a> property.<br/><br/>
3.) XPaths - addresses content via XPaths (assuming an XML view of the
content). Use the <a class="localLink"
href="http://schema.org/xpath">xpath</a> property.<br/><br/> For more
sophisticated markup of speakable sections beyond simple ID references,
either CSS selectors or XPath expressions to pick out document section(s)
as speakable. For this we define a supporting type, <a class="localLink"
href="http://schema.org/SpeakableSpecification">SpeakableSpecification</a>
which is defined to be a possible value of the <em>speakable</em> property.

A speakable should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SpeakableSpecification']>

=item C<Str>

=back

=head2 C<specialty>

One of the domain specialities to which this web page's content applies.

A specialty should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Specialty']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

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
