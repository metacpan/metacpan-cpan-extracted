use utf8;

package SemanticWeb::Schema::BroadcastEvent;

# ABSTRACT: An over the air or online broadcast event.

use Moo;

extends qw/ SemanticWeb::Schema::PublicationEvent /;


use MooX::JSON_LD 'BroadcastEvent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has broadcast_of_event => (
    is        => 'rw',
    predicate => '_has_broadcast_of_event',
    json_ld   => 'broadcastOfEvent',
);



has is_live_broadcast => (
    is        => 'rw',
    predicate => '_has_is_live_broadcast',
    json_ld   => 'isLiveBroadcast',
);



has subtitle_language => (
    is        => 'rw',
    predicate => '_has_subtitle_language',
    json_ld   => 'subtitleLanguage',
);



has video_format => (
    is        => 'rw',
    predicate => '_has_video_format',
    json_ld   => 'videoFormat',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::BroadcastEvent - An over the air or online broadcast event.

=head1 VERSION

version v5.0.1

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

=head2 C<_has_broadcast_of_event>

A predicate for the L</broadcast_of_event> attribute.

=head2 C<is_live_broadcast>

C<isLiveBroadcast>

True is the broadcast is of a live event.

A is_live_broadcast should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_is_live_broadcast>

A predicate for the L</is_live_broadcast> attribute.

=head2 C<subtitle_language>

C<subtitleLanguage>

=for html <p>Languages in which subtitles/captions are available, in <a
href="http://tools.ietf.org/html/bcp47">IETF BCP 47 standard format</a>.<p>

A subtitle_language should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Language']>

=item C<Str>

=back

=head2 C<_has_subtitle_language>

A predicate for the L</subtitle_language> attribute.

=head2 C<video_format>

C<videoFormat>

The type of screening or video broadcast used (e.g. IMAX, 3D, SD, HD,
etc.).

A video_format should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_video_format>

A predicate for the L</video_format> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::PublicationEvent>

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
