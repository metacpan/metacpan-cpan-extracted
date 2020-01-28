use utf8;

package SemanticWeb::Schema::Question;

# ABSTRACT: A specific question - e

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Question';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.0';


has accepted_answer => (
    is        => 'rw',
    predicate => '_has_accepted_answer',
    json_ld   => 'acceptedAnswer',
);



has answer_count => (
    is        => 'rw',
    predicate => '_has_answer_count',
    json_ld   => 'answerCount',
);



has downvote_count => (
    is        => 'rw',
    predicate => '_has_downvote_count',
    json_ld   => 'downvoteCount',
);



has suggested_answer => (
    is        => 'rw',
    predicate => '_has_suggested_answer',
    json_ld   => 'suggestedAnswer',
);



has upvote_count => (
    is        => 'rw',
    predicate => '_has_upvote_count',
    json_ld   => 'upvoteCount',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Question - A specific question - e

=head1 VERSION

version v6.0.0

=head1 DESCRIPTION

A specific question - e.g. from a user seeking answers online, or collected
in a Frequently Asked Questions (FAQ) document.

=head1 ATTRIBUTES

=head2 C<accepted_answer>

C<acceptedAnswer>

The answer(s) that has been accepted as best, typically on a
Question/Answer site. Sites vary in their selection mechanisms, e.g.
drawing on community opinion and/or the view of the Question author.

A accepted_answer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Answer']>

=item C<InstanceOf['SemanticWeb::Schema::ItemList']>

=back

=head2 C<_has_accepted_answer>

A predicate for the L</accepted_answer> attribute.

=head2 C<answer_count>

C<answerCount>

The number of answers this question has received.

A answer_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_answer_count>

A predicate for the L</answer_count> attribute.

=head2 C<downvote_count>

C<downvoteCount>

The number of downvotes this question, answer or comment has received from
the community.

A downvote_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_downvote_count>

A predicate for the L</downvote_count> attribute.

=head2 C<suggested_answer>

C<suggestedAnswer>

An answer (possibly one of several, possibly incorrect) to a Question, e.g.
on a Question/Answer site.

A suggested_answer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Answer']>

=item C<InstanceOf['SemanticWeb::Schema::ItemList']>

=back

=head2 C<_has_suggested_answer>

A predicate for the L</suggested_answer> attribute.

=head2 C<upvote_count>

C<upvoteCount>

The number of upvotes this question, answer or comment has received from
the community.

A upvote_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<_has_upvote_count>

A predicate for the L</upvote_count> attribute.

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
