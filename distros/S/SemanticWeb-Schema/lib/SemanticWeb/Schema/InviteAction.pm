use utf8;

package SemanticWeb::Schema::InviteAction;

# ABSTRACT: The act of asking someone to attend an event

use Moo;

extends qw/ SemanticWeb::Schema::CommunicateAction /;


use MooX::JSON_LD 'InviteAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has event => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'event',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::InviteAction - The act of asking someone to attend an event

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

The act of asking someone to attend an event. Reciprocal of RsvpAction.

=head1 ATTRIBUTES

=head2 C<event>

Upcoming or past event associated with this place, organization, or action.

A event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

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
