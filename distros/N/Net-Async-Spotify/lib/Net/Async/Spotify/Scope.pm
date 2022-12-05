package Net::Async::Spotify::Scope;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

=encoding utf8

=head1 NAME

Net::Async::Spotify::Scope - Helper for Spotify Scopes

=head1 SYNOPSIS

    use Net::Async::Spotify::Scope qw(scopes images);

    my @all = scopes();
    my @needed = scopes(qw(ugc_image_upload user_read_recently_played));

    my @images_scopes = images();
    my $mod_lib = Net::Async::Spotify::Scope::user_library_modify();

    # Safe to call, even if Scope does not exist
    my $dne = Net::Async::Spotify::Scope::dne();

=head1 DESCRIPTION

Representation for Spotify Authorization Scopes defined in https://developer.spotify.com/documentation/general/guides/scopes
methods exported will group scopes as categorized by Spotify.

=cut

use Log::Any qw($log);

use Exporter 'import';

our @EXPORT_OK = qw(scopes images listening_history spotify_connect playback playlists follow library users);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my %scopes = map { $_ =~ s/-/_/gr => $_  } qw(ugc-image-upload user-read-recently-played user-read-playback-state user-top-read app-remote-control playlist-modify-public user-modify-playback-state playlist-modify-private user-follow-modify user-read-currently-playing user-follow-read user-library-modify user-read-playback-position playlist-read-private user-read-email user-read-private user-library-read playlist-read-collaborative streaming);

# TODO: Add support for endpoints allowed for each Scope.

=head1 METHODS

=head2 scopes

Returns list of Spotify Scopes, if no specific scopes requested; will return all scopes.

=cut

sub scopes {
    my @keys = @_;
    if ( @keys ) {
        # Get only defined scopes only
        @scopes{ grep { $scopes{$_} } @keys };
    } else {
        values %scopes;
    }
}

=head2 images

Returns list of Spotify Scopes for Images

=cut

sub images { @scopes{qw(ugc_image_upload)} }

=head2 listening_history

Returns list of Spotify Scopes for Listening History

=cut

sub listening_history { @scopes{qw(user_read_recently_played user_top_read user_read_playback_position)} }

=head2 spotify_connect

Returns list of Spotify Scopes for Spotify Connect

=cut

sub spotify_connect { @scopes{qw(user_read_playback_state user_modify_playback_state user_read_currently_playing)} }

=head2 playback

Returns list of Spotify Scopes for Playback

=cut

sub playback { @scopes{qw(app_remote_control streaming)} }

=head2 playlists

Returns list of Spotify Scopes for Playlists

=cut

sub playlists { @scopes{qw(playlist_modify_public playlist_modify_private playlist_read_private playlist_read_collaborative)} }

=head2 follow

Returns list of Spotify Scopes for Follow

=cut

sub follow { @scopes{qw(user_follow_modify user_follow_read)} }

=head2 library

Returns list of Spotify Scopes for Library

=cut

sub library { @scopes{qw(user_library_modify user_library_read)} }

=head2 users

Retruns list of Spotify Scopes for Users

=cut

sub users { @scopes{qw(user_read_email user_read_private)} }

=head2 AUTOLOAD

An addition to this helper is that it will check if sub name called corresponde to any Spotify scope.
And return a Scope, or log a warn message and return empty list when not found.

=cut

sub AUTOLOAD {
    my ($s) = our $AUTOLOAD =~ m{^.*::([^:]+)$};
    # Check if exists as individual scope. Else return empty list.
    return $scopes{$s} if exists $scopes{$s};
    return $scopes{$s =~ s/-/_/gr} if exists $scopes{$s =~ s/-/_/gr};
    $log->warnf('Could not find Spotify Scope, for: %s', $s);
    return '';
}

1;
