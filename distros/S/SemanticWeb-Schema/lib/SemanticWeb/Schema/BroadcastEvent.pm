use utf8;

package SemanticWeb::Schema::BroadcastEvent;

# ABSTRACT: An over the air or online broadcast event.

use Moo;

extends qw/ SemanticWeb::Schema::PublicationEvent /;


use MooX::JSON_LD 'BroadcastEvent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has broadcast_of_event => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'broadcastOfEvent',
);



has is_live_broadcast => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isLiveBroadcast',
);



has video_format => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'videoFormat',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BroadcastEvent - An over the air or online broadcast event.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

An over the air or online broadcast event.

=head1 ATTRIBUTES

=head2 C<broadcast_of_event>

C<broadcastOfEvent>

The event being broadcast such as a sporting event or awards ceremony.

A broadcast_of_event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<is_live_broadcast>

C<isLiveBroadcast>

True is the broadcast is of a live event.

A is_live_broadcast should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<video_format>

C<videoFormat>

The type of screening or video broadcast used (e.g. IMAX, 3D, SD, HD,
etc.).

A video_format should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::PublicationEvent>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
