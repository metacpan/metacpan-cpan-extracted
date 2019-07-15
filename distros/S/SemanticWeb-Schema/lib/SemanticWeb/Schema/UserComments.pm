use utf8;

package SemanticWeb::Schema::UserComments;

# ABSTRACT: UserInteraction and its subtypes is an old way of talking about users interacting with pages

use Moo;

extends qw/ SemanticWeb::Schema::UserInteraction /;


use MooX::JSON_LD 'UserComments';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has comment_text => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'commentText',
);



has comment_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'commentTime',
);



has creator => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'creator',
);



has discusses => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'discusses',
);



has reply_to_url => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'replyToUrl',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::UserComments - UserInteraction and its subtypes is an old way of talking about users interacting with pages

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html UserInteraction and its subtypes is an old way of talking about users
interacting with pages. It is generally better to use <a class="localLink"
href="http://schema.org/Action">Action</a>-based vocabulary, alongside
types such as <a class="localLink"
href="http://schema.org/Comment">Comment</a>.

=head1 ATTRIBUTES

=head2 C<comment_text>

C<commentText>

The text of the UserComment.

A comment_text should be one of the following types:

=over

=item C<Str>

=back

=head2 C<comment_time>

C<commentTime>

The time at which the UserComment was made.

A comment_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<creator>

The creator/author of this CreativeWork. This is the same as the Author
property for CreativeWork.

A creator should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<discusses>

Specifies the CreativeWork associated with the UserComment.

A discusses should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<reply_to_url>

C<replyToUrl>

The URL at which a reply may be posted to the specified UserComment.

A reply_to_url should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::UserInteraction>

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
