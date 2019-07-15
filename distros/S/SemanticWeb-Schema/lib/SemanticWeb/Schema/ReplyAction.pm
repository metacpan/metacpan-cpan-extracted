use utf8;

package SemanticWeb::Schema::ReplyAction;

# ABSTRACT: The act of responding to a question/message asked/sent by the object

use Moo;

extends qw/ SemanticWeb::Schema::CommunicateAction /;


use MooX::JSON_LD 'ReplyAction';
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

SemanticWeb::Schema::ReplyAction - The act of responding to a question/message asked/sent by the object

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html The act of responding to a question/message asked/sent by the object.
Related to <a class="localLink"
href="http://schema.org/AskAction">AskAction</a><br/><br/> Related
actions:<br/><br/> <ul> <li><a class="localLink"
href="http://schema.org/AskAction">AskAction</a>: Appears generally as an
origin of a ReplyAction.</li> </ul> 

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
