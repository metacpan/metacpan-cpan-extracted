use utf8;

package SemanticWeb::Schema::VideoObject;

# ABSTRACT: A video file.

use Moo;

extends qw/ SemanticWeb::Schema::MediaObject /;


use MooX::JSON_LD 'VideoObject';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has actor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'actor',
);



has actors => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'actors',
);



has caption => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'caption',
);



has director => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'director',
);



has directors => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'directors',
);



has music_by => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'musicBy',
);



has thumbnail => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'thumbnail',
);



has transcript => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'transcript',
);



has video_frame_size => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'videoFrameSize',
);



has video_quality => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'videoQuality',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::VideoObject - A video file.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A video file.

=head1 ATTRIBUTES

=head2 C<actor>

An actor, e.g. in tv, radio, movie, video games etc., or in an event.
Actors can be associated with individual items or with a series, episode,
clip.

A actor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<actors>

An actor, e.g. in tv, radio, movie, video games etc. Actors can be
associated with individual items or with a series, episode, clip.

A actors should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<caption>

The caption for this object.

A caption should be one of the following types:

=over

=item C<Str>

=back

=head2 C<director>

A director of e.g. tv, radio, movie, video gaming etc. content, or of an
event. Directors can be associated with individual items or with a series,
episode, clip.

A director should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<directors>

A director of e.g. tv, radio, movie, video games etc. content. Directors
can be associated with individual items or with a series, episode, clip.

A directors should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<music_by>

C<musicBy>

The composer of the soundtrack.

A music_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=item C<InstanceOf['SemanticWeb::Schema::MusicGroup']>

=back

=head2 C<thumbnail>

Thumbnail image for an image or video.

A thumbnail should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=back

=head2 C<transcript>

If this MediaObject is an AudioObject or VideoObject, the transcript of
that object.

A transcript should be one of the following types:

=over

=item C<Str>

=back

=head2 C<video_frame_size>

C<videoFrameSize>

The frame size of the video.

A video_frame_size should be one of the following types:

=over

=item C<Str>

=back

=head2 C<video_quality>

C<videoQuality>

The quality of the video.

A video_quality should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MediaObject>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
