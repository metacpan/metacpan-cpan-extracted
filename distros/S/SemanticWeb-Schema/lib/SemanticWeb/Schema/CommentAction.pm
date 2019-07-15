use utf8;

package SemanticWeb::Schema::CommentAction;

# ABSTRACT: The act of generating a comment about a subject.

use Moo;

extends qw/ SemanticWeb::Schema::CommunicateAction /;


use MooX::JSON_LD 'CommentAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has result_comment => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'resultComment',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CommentAction - The act of generating a comment about a subject.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

The act of generating a comment about a subject.

=head1 ATTRIBUTES

=head2 C<result_comment>

C<resultComment>

A sub property of result. The Comment created or sent as a result of this
action.

A result_comment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Comment']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CommunicateAction>

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
