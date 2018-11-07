use utf8;

package SemanticWeb::Schema::Comment;

# ABSTRACT: A comment on an item - for example

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Comment';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has downvote_count => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'downvoteCount',
);



has parent_item => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'parentItem',
);



has upvote_count => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'upvoteCount',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Comment - A comment on an item - for example

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

=for html A comment on an item - for example, a comment on a blog post. The comment's
content is expressed via the <a class="localLink"
href="http://schema.org/text">text</a> property, and its topic via <a
class="localLink" href="http://schema.org/about">about</a>, properties
shared with all CreativeWorks.

=head1 ATTRIBUTES

=head2 C<downvote_count>

C<downvoteCount>

The number of downvotes this question, answer or comment has received from
the community.

A downvote_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<parent_item>

C<parentItem>

The parent of a question, answer or item in general.

A parent_item should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Question']>

=back

=head2 C<upvote_count>

C<upvoteCount>

The number of upvotes this question, answer or comment has received from
the community.

A upvote_count should be one of the following types:

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
