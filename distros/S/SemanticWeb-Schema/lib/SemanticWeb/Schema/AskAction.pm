use utf8;

package SemanticWeb::Schema::AskAction;

# ABSTRACT: The act of posing a question / favor to someone

use Moo;

extends qw/ SemanticWeb::Schema::CommunicateAction /;


use MooX::JSON_LD 'AskAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has question => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'question',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AskAction - The act of posing a question / favor to someone

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

=for html The act of posing a question / favor to someone.<br/><br/> Related
actions:<br/><br/> <ul> <li><a class="localLink"
href="http://schema.org/ReplyAction">ReplyAction</a>: Appears generally as
a response to AskAction.</li> </ul> 

=head1 ATTRIBUTES

=head2 C<question>

A sub property of object. A question.

A question should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Question']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CommunicateAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
