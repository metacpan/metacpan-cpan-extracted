use utf8;

package SemanticWeb::Schema::PublicationIssue;

# ABSTRACT: A part of a successively published publication such as a periodical or publication volume

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'PublicationIssue';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.2';


has issue_number => (
    is        => 'rw',
    predicate => '_has_issue_number',
    json_ld   => 'issueNumber',
);



has page_end => (
    is        => 'rw',
    predicate => '_has_page_end',
    json_ld   => 'pageEnd',
);



has page_start => (
    is        => 'rw',
    predicate => '_has_page_start',
    json_ld   => 'pageStart',
);



has pagination => (
    is        => 'rw',
    predicate => '_has_pagination',
    json_ld   => 'pagination',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PublicationIssue - A part of a successively published publication such as a periodical or publication volume

=head1 VERSION

version v7.0.2

=head1 DESCRIPTION

=for html <p>A part of a successively published publication such as a periodical or
publication volume, often numbered, usually containing a grouping of works
such as articles.<br/><br/> See also <a
href="http://blog.schema.org/2014/09/schemaorg-support-for-bibliographic_2.
html">blog post</a>.<p>

=head1 ATTRIBUTES

=head2 C<issue_number>

C<issueNumber>

Identifies the issue of publication; for example, "iii" or "2".

A issue_number should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<Str>

=back

=head2 C<_has_issue_number>

A predicate for the L</issue_number> attribute.

=head2 C<page_end>

C<pageEnd>

The page on which the work ends; for example "138" or "xvi".

A page_end should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<Str>

=back

=head2 C<_has_page_end>

A predicate for the L</page_end> attribute.

=head2 C<page_start>

C<pageStart>

The page on which the work starts; for example "135" or "xiii".

A page_start should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=item C<Str>

=back

=head2 C<_has_page_start>

A predicate for the L</page_start> attribute.

=head2 C<pagination>

Any description of pages that is not separated into pageStart and pageEnd;
for example, "1-6, 9, 55" or "10-12, 46-49".

A pagination should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_pagination>

A predicate for the L</pagination> attribute.

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
