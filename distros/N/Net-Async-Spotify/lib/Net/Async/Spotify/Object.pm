package Net::Async::Spotify::Object;

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

use Future::AsyncAwait;
use Log::Any qw($log);
use Syntax::Keyword::Try;
use Path::Tiny;
use Module::Path qw(module_path);
use Module::Runtime qw(require_module);
use Net::Async::Spotify::Util qw(response_object_map);
use Net::Async::Spotify::Object::General;

=encoding utf8

=head1 NAME

    Net::Async::Spotify::Object - Common Wrapper package for Spotify response Objects

=head1 SYNOPSIS

To be used internally, and it will be used as a response to L<Net::Async::Spotify::API>
However this is how it's actually being used:

    use Net::Async::Spotify::Object;

    my $sp_json_decoded_res = {danceability => 0.735,,...}; # Audio Features response.
    my $obj = Net::Async::Spotify::Object->new(
        $sp_json_decoded_res,
        {
            response_objs => ['features'],
            uri => 'https://api.spotify.com/v1/audio-features/{id}',
        },
    );
    ref $obj; # => Net::Async::Spotify::Object::AudioFeatures

=head1 DESCRIPTION

Common wrapper for Spotify response Objects. To be used to dynamically be able to create
resonse objects.
It does so by so by figuring out needed Object type using L<Net::Async::Spotify::Util::response_object_map>
and returning a new instance of that L<perlsyn/"Objects">. When it can't determine an exact object type it will
return an instance of L<Net::Async::Spotify::Object::General>.
Note that some responses are paginated, so might contain L<Net::Async::Spotify::Object::Paging>.
and if it's an erroneous response it will be L<Net::Async::Spotify::Object::Error>.

=head1 PARAMETERS

We would need to pass what we think this Object might be along with the content.

=over 4

=item possible_types

A list of possible types for this object we want to create.

=item data

the content that we want to create the object for.

=back

=cut

my $available_types;
BEGIN {
    # Include all Spotify Object classes
    my $current_path = path(module_path(__PACKAGE__) =~ s/\.pm/\//r );
    push @$available_types, $_->basename =~ s/\.pm//r for $current_path->child('Generated')->children(qr/.pm$/);
    require_module(join '::', __PACKAGE__, $_) for @$available_types;
}

sub new {
    my ( $obj, $data, $res_hash ) = @_;

    my $class = response_object_map($available_types, $res_hash);
    $log->debugf('Response object mapping; params: %s | Class selected: %s', $res_hash, $class);
    # return generic when not found.
    return Net::Async::Spotify::Object::General->new($data->%*) unless defined $class;

    my $content = [];
    try {
        # Check if pagination or Error object.
        if ( exists $data->{items} and exists $data->{limit} and exists $data->{total} ) {
            push @$content, $class->new($_->%*) for $data->{items}->@*;
            delete $data->{items};
            my $page = Net::Async::Spotify::Object::Paging->new($data->%*);
            $page->{items} = $content;
            return $page;
            # TODO: Add error checking.
        } else {
            return $class->new($data->%*);
        }
    } catch ($e) {
        $log->warnf('Could not create Spotify Object %s | error: %s | res_hash: %s ', $class, $e, $res_hash);
    }
    return Net::Async::Spotify::Object::General->new($data->%*);
}

1;

=head1 Objects

Here is a list of the current available Spotify Object types.
Found in link here L<https://developer.spotify.com/documentation/web-api/reference/#objects-index>

=over 4

=item *

L<Net::Async::Spotify::Object::Album>

=item *

L<Net::Async::Spotify::Object::AlbumRestriction>

=item *

L<Net::Async::Spotify::Object::Artist>

=item *

L<Net::Async::Spotify::Object::AudioFeatures>

=item *

L<Net::Async::Spotify::Object::Base>

=item *

L<Net::Async::Spotify::Object::Category>

=item *

L<Net::Async::Spotify::Object::Context>

=item *

L<Net::Async::Spotify::Object::Copyright>

=item *

L<Net::Async::Spotify::Object::CurrentlyPlaying>

=item *

L<Net::Async::Spotify::Object::CurrentlyPlayingContext>

=item *

L<Net::Async::Spotify::Object::Cursor>

=item *

L<Net::Async::Spotify::Object::CursorPaging>

=item *

L<Net::Async::Spotify::Object::Device>

=item *

L<Net::Async::Spotify::Object::Devices>

=item *

L<Net::Async::Spotify::Object::Disallows>

=item *

L<Net::Async::Spotify::Object::Episode>

=item *

L<Net::Async::Spotify::Object::EpisodeRestriction>

=item *

L<Net::Async::Spotify::Object::Error>

=item *

L<Net::Async::Spotify::Object::ExplicitContentSettings>

=item *

L<Net::Async::Spotify::Object::ExternalId>

=item *

L<Net::Async::Spotify::Object::ExternalUrl>

=item *

L<Net::Async::Spotify::Object::Followers>

=item *

L<Net::Async::Spotify::Object::General>

=item *

L<Net::Async::Spotify::Object::Image>

=item *

L<Net::Async::Spotify::Object::LinkedTrack>

=item *

L<Net::Async::Spotify::Object::Paging>

=item *

L<Net::Async::Spotify::Object::PlayHistory>

=item *

L<Net::Async::Spotify::Object::PlayerError>

=item *

L<Net::Async::Spotify::Object::Playlist>

=item *

L<Net::Async::Spotify::Object::PlaylistTrack>

=item *

L<Net::Async::Spotify::Object::PlaylistTracksRef>

=item *

L<Net::Async::Spotify::Object::PrivateUser>

=item *

L<Net::Async::Spotify::Object::PublicUser>

=item *

L<Net::Async::Spotify::Object::RecommendationSeed>

=item *

L<Net::Async::Spotify::Object::Recommendations>

=item *

L<Net::Async::Spotify::Object::ResumePoint>

=item *

L<Net::Async::Spotify::Object::SavedAlbum>

=item *

L<Net::Async::Spotify::Object::SavedEpisode>

=item *

L<Net::Async::Spotify::Object::SavedShow>

=item *

L<Net::Async::Spotify::Object::SavedTrack>

=item *

L<Net::Async::Spotify::Object::Show>

=item *

L<Net::Async::Spotify::Object::SimplifiedAlbum>

=item *

L<Net::Async::Spotify::Object::SimplifiedArtist>

=item *

L<Net::Async::Spotify::Object::SimplifiedEpisode>

=item *

L<Net::Async::Spotify::Object::SimplifiedPlaylist>

=item *

L<Net::Async::Spotify::Object::SimplifiedShow>

=item *

L<Net::Async::Spotify::Object::SimplifiedTrack>

=item *

L<Net::Async::Spotify::Object::Track>

=item *

L<Net::Async::Spotify::Object::TrackRestriction>

=item *

L<Net::Async::Spotify::Object::TuneableTrack>

=back

=cut
