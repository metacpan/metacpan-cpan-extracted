use utf8;

package SemanticWeb::Schema::LinkRole;

# ABSTRACT: A Role that represents a Web link e

use Moo;

extends qw/ SemanticWeb::Schema::Role /;


use MooX::JSON_LD 'LinkRole';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has in_language => (
    is        => 'rw',
    predicate => '_has_in_language',
    json_ld   => 'inLanguage',
);



has link_relationship => (
    is        => 'rw',
    predicate => '_has_link_relationship',
    json_ld   => 'linkRelationship',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::LinkRole - A Role that represents a Web link e

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A Role that represents a Web link e.g. as expressed via the 'url' property.
Its linkRelationship property can indicate URL-based and plain textual link
types e.g. those in IANA link registry or others such as 'amphtml'. This
structure provides a placeholder where details from HTML's link element can
be represented outside of HTML, e.g. in JSON-LD feeds.

=head1 ATTRIBUTES

=head2 C<in_language>

C<inLanguage>

=for html <p>The language of the content or performance or used in an action. Please
use one of the language codes from the <a
href="http://tools.ietf.org/html/bcp47">IETF BCP 47 standard</a>. See also
<a class="localLink"
href="http://schema.org/availableLanguage">availableLanguage</a>.<p>

A in_language should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Language']>

=item C<Str>

=back

=head2 C<_has_in_language>

A predicate for the L</in_language> attribute.

=head2 C<link_relationship>

C<linkRelationship>

Indicates the relationship type of a Web link.

A link_relationship should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_link_relationship>

A predicate for the L</link_relationship> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Role>

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
