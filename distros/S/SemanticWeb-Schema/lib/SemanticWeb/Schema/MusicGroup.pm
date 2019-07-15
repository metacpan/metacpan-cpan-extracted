use utf8;

package SemanticWeb::Schema::MusicGroup;

# ABSTRACT: A musical group

use Moo;

extends qw/ SemanticWeb::Schema::PerformingGroup /;


use MooX::JSON_LD 'MusicGroup';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has album => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'album',
);



has albums => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'albums',
);



has genre => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'genre',
);



has music_group_member => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'musicGroupMember',
);



has track => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'track',
);



has tracks => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'tracks',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MusicGroup - A musical group

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A musical group, such as a band, an orchestra, or a choir. Can also be a
solo musician.

=head1 ATTRIBUTES

=head2 C<album>

A music album.

A album should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicAlbum']>

=back

=head2 C<albums>

A collection of music albums.

A albums should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicAlbum']>

=back

=head2 C<genre>

Genre of the creative work, broadcast channel or group.

A genre should be one of the following types:

=over

=item C<Str>

=back

=head2 C<music_group_member>

C<musicGroupMember>

A member of a music group&#x2014;for example, John, Paul, George, or Ringo.

A music_group_member should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<track>

A music recording (track)&#x2014;usually a single song. If an ItemList is
given, the list should contain items of type MusicRecording.

A track should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ItemList']>

=item C<InstanceOf['SemanticWeb::Schema::MusicRecording']>

=back

=head2 C<tracks>

A music recording (track)&#x2014;usually a single song.

A tracks should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicRecording']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::PerformingGroup>

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
