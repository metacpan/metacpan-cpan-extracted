use utf8;

package SemanticWeb::Schema::ScreeningEvent;

# ABSTRACT: A screening of a movie or other video.

use Moo;

extends qw/ SemanticWeb::Schema::Event /;


use MooX::JSON_LD 'ScreeningEvent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


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



has work_presented => (
    is        => 'rw',
    predicate => '_has_work_presented',
    json_ld   => 'workPresented',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ScreeningEvent - A screening of a movie or other video.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A screening of a movie or other video.

=head1 ATTRIBUTES

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

=head2 C<work_presented>

C<workPresented>

The movie presented during this event.

A work_presented should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Movie']>

=back

=head2 C<_has_work_presented>

A predicate for the L</work_presented> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Event>

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
