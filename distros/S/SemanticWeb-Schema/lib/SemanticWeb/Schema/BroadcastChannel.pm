use utf8;

package SemanticWeb::Schema::BroadcastChannel;

# ABSTRACT: A unique instance of a BroadcastService on a CableOrSatelliteService lineup.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'BroadcastChannel';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has broadcast_channel_id => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'broadcastChannelId',
);



has broadcast_frequency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'broadcastFrequency',
);



has broadcast_service_tier => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'broadcastServiceTier',
);



has genre => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'genre',
);



has in_broadcast_lineup => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'inBroadcastLineup',
);



has provides_broadcast_service => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'providesBroadcastService',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BroadcastChannel - A unique instance of a BroadcastService on a CableOrSatelliteService lineup.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A unique instance of a BroadcastService on a CableOrSatelliteService
lineup.

=head1 ATTRIBUTES

=head2 C<broadcast_channel_id>

C<broadcastChannelId>

The unique address by which the BroadcastService can be identified in a
provider lineup. In US, this is typically a number.

A broadcast_channel_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<broadcast_frequency>

C<broadcastFrequency>

The frequency used for over-the-air broadcasts. Numeric values or simple
ranges e.g. 87-99. In addition a shortcut idiom is supported for frequences
of AM and FM radio channels, e.g. "87 FM".

A broadcast_frequency should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BroadcastFrequencySpecification']>

=item C<Str>

=back

=head2 C<broadcast_service_tier>

C<broadcastServiceTier>

The type of service required to have access to the channel (e.g. Standard
or Premium).

A broadcast_service_tier should be one of the following types:

=over

=item C<Str>

=back

=head2 C<genre>

Genre of the creative work, broadcast channel or group.

A genre should be one of the following types:

=over

=item C<Str>

=back

=head2 C<in_broadcast_lineup>

C<inBroadcastLineup>

The CableOrSatelliteService offering the channel.

A in_broadcast_lineup should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CableOrSatelliteService']>

=back

=head2 C<provides_broadcast_service>

C<providesBroadcastService>

The BroadcastService offered on this channel.

A provides_broadcast_service should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BroadcastService']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

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
