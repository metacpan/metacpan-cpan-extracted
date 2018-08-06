package SemanticWeb::Schema::FollowAction;

# ABSTRACT: <p>The act of forming a personal connection with someone/something (object) unidirectionally/asymmetrically to get updates polled from

use Moo;

extends qw/ SemanticWeb::Schema::InteractAction /;


use MooX::JSON_LD 'FollowAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has followee => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'followee',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::FollowAction - <p>The act of forming a personal connection with someone/something (object) unidirectionally/asymmetrically to get updates polled from

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>The act of forming a personal connection with someone/something (object)
unidirectionally/asymmetrically to get updates polled from.</p> <p>Related
actions:</p> <ul> <li><a class="localLink"
href="http://schema.org/BefriendAction">BefriendAction</a>: Unlike
BefriendAction, FollowAction implies that the connection is <em>not</em>
necessarily reciprocal.</li> <li><a class="localLink"
href="http://schema.org/SubscribeAction">SubscribeAction</a>: Unlike
SubscribeAction, FollowAction implies that the follower acts as an active
agent constantly/actively polling for updates.</li> <li><a
class="localLink"
href="http://schema.org/RegisterAction">RegisterAction</a>: Unlike
RegisterAction, FollowAction implies that the agent is interested in
continuing receiving updates from the object.</li> <li><a class="localLink"
href="http://schema.org/JoinAction">JoinAction</a>: Unlike JoinAction,
FollowAction implies that the agent is interested in getting updates from
the object.</li> <li><a class="localLink"
href="http://schema.org/TrackAction">TrackAction</a>: Unlike TrackAction,
FollowAction refers to the polling of updates of all aspects of animate
objects rather than the location of inanimate objects (e.g. you track a
package, but you don't follow it).</li> </ul> 

=head1 ATTRIBUTES

=head2 C<followee>

A sub property of object. The person or organization being followed.

A followee should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::InteractAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
