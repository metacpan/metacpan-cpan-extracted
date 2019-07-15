use utf8;

package SemanticWeb::Schema::BroadcastService;

# ABSTRACT: A delivery service through which content is provided via broadcast over the air or online.

use Moo;

extends qw/ SemanticWeb::Schema::Service /;


use MooX::JSON_LD 'BroadcastService';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has area => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'area',
);



has broadcast_affiliate_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'broadcastAffiliateOf',
);



has broadcast_display_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'broadcastDisplayName',
);



has broadcast_frequency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'broadcastFrequency',
);



has broadcast_timezone => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'broadcastTimezone',
);



has broadcaster => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'broadcaster',
);



has has_broadcast_channel => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasBroadcastChannel',
);



has parent_service => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'parentService',
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

SemanticWeb::Schema::BroadcastService - A delivery service through which content is provided via broadcast over the air or online.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A delivery service through which content is provided via broadcast over the
air or online.

=head1 ATTRIBUTES

=head2 C<area>

The area within which users can expect to reach the broadcast service.

A area should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<broadcast_affiliate_of>

C<broadcastAffiliateOf>

The media network(s) whose content is broadcast on this station.

A broadcast_affiliate_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<broadcast_display_name>

C<broadcastDisplayName>

The name displayed in the channel guide. For many US affiliates, it is the
network name.

A broadcast_display_name should be one of the following types:

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

=head2 C<broadcast_timezone>

C<broadcastTimezone>

=for html The timezone in <a href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601
format</a> for which the service bases its broadcasts

A broadcast_timezone should be one of the following types:

=over

=item C<Str>

=back

=head2 C<broadcaster>

The organization owning or operating the broadcast service.

A broadcaster should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<has_broadcast_channel>

C<hasBroadcastChannel>

A broadcast channel of a broadcast service.

A has_broadcast_channel should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BroadcastChannel']>

=back

=head2 C<parent_service>

C<parentService>

A broadcast service to which the broadcast service may belong to such as
regional variations of a national channel.

A parent_service should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BroadcastService']>

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

L<SemanticWeb::Schema::Service>

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
