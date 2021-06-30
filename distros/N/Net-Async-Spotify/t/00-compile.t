use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 134 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Net/Async/Spotify.pm',
    'Net/Async/Spotify/API.pm',
    'Net/Async/Spotify/API/Albums.pm',
    'Net/Async/Spotify/API/Artists.pm',
    'Net/Async/Spotify/API/Base.pm',
    'Net/Async/Spotify/API/Browse.pm',
    'Net/Async/Spotify/API/Episodes.pm',
    'Net/Async/Spotify/API/Follow.pm',
    'Net/Async/Spotify/API/Generated/Albums.pm',
    'Net/Async/Spotify/API/Generated/Artists.pm',
    'Net/Async/Spotify/API/Generated/Browse.pm',
    'Net/Async/Spotify/API/Generated/Episodes.pm',
    'Net/Async/Spotify/API/Generated/Follow.pm',
    'Net/Async/Spotify/API/Generated/Library.pm',
    'Net/Async/Spotify/API/Generated/Markets.pm',
    'Net/Async/Spotify/API/Generated/Personalization.pm',
    'Net/Async/Spotify/API/Generated/Player.pm',
    'Net/Async/Spotify/API/Generated/Playlists.pm',
    'Net/Async/Spotify/API/Generated/Search.pm',
    'Net/Async/Spotify/API/Generated/Shows.pm',
    'Net/Async/Spotify/API/Generated/Tracks.pm',
    'Net/Async/Spotify/API/Generated/Users.pm',
    'Net/Async/Spotify/API/Library.pm',
    'Net/Async/Spotify/API/Markets.pm',
    'Net/Async/Spotify/API/Personalization.pm',
    'Net/Async/Spotify/API/Player.pm',
    'Net/Async/Spotify/API/Playlists.pm',
    'Net/Async/Spotify/API/Search.pm',
    'Net/Async/Spotify/API/Shows.pm',
    'Net/Async/Spotify/API/Tracks.pm',
    'Net/Async/Spotify/API/Users.pm',
    'Net/Async/Spotify/Object.pm',
    'Net/Async/Spotify/Object/Album.pm',
    'Net/Async/Spotify/Object/AlbumRestriction.pm',
    'Net/Async/Spotify/Object/Artist.pm',
    'Net/Async/Spotify/Object/AudioFeatures.pm',
    'Net/Async/Spotify/Object/Base.pm',
    'Net/Async/Spotify/Object/Category.pm',
    'Net/Async/Spotify/Object/Context.pm',
    'Net/Async/Spotify/Object/Copyright.pm',
    'Net/Async/Spotify/Object/CurrentlyPlaying.pm',
    'Net/Async/Spotify/Object/CurrentlyPlayingContext.pm',
    'Net/Async/Spotify/Object/Cursor.pm',
    'Net/Async/Spotify/Object/CursorPaging.pm',
    'Net/Async/Spotify/Object/Device.pm',
    'Net/Async/Spotify/Object/Devices.pm',
    'Net/Async/Spotify/Object/Disallows.pm',
    'Net/Async/Spotify/Object/Episode.pm',
    'Net/Async/Spotify/Object/EpisodeRestriction.pm',
    'Net/Async/Spotify/Object/Error.pm',
    'Net/Async/Spotify/Object/ExplicitContentSettings.pm',
    'Net/Async/Spotify/Object/ExternalId.pm',
    'Net/Async/Spotify/Object/ExternalUrl.pm',
    'Net/Async/Spotify/Object/Followers.pm',
    'Net/Async/Spotify/Object/General.pm',
    'Net/Async/Spotify/Object/Generated/Album.pm',
    'Net/Async/Spotify/Object/Generated/AlbumRestriction.pm',
    'Net/Async/Spotify/Object/Generated/Artist.pm',
    'Net/Async/Spotify/Object/Generated/AudioFeatures.pm',
    'Net/Async/Spotify/Object/Generated/Category.pm',
    'Net/Async/Spotify/Object/Generated/Context.pm',
    'Net/Async/Spotify/Object/Generated/Copyright.pm',
    'Net/Async/Spotify/Object/Generated/CurrentlyPlaying.pm',
    'Net/Async/Spotify/Object/Generated/CurrentlyPlayingContext.pm',
    'Net/Async/Spotify/Object/Generated/Cursor.pm',
    'Net/Async/Spotify/Object/Generated/CursorPaging.pm',
    'Net/Async/Spotify/Object/Generated/Device.pm',
    'Net/Async/Spotify/Object/Generated/Devices.pm',
    'Net/Async/Spotify/Object/Generated/Disallows.pm',
    'Net/Async/Spotify/Object/Generated/Episode.pm',
    'Net/Async/Spotify/Object/Generated/EpisodeRestriction.pm',
    'Net/Async/Spotify/Object/Generated/Error.pm',
    'Net/Async/Spotify/Object/Generated/ExplicitContentSettings.pm',
    'Net/Async/Spotify/Object/Generated/ExternalId.pm',
    'Net/Async/Spotify/Object/Generated/ExternalUrl.pm',
    'Net/Async/Spotify/Object/Generated/Followers.pm',
    'Net/Async/Spotify/Object/Generated/Image.pm',
    'Net/Async/Spotify/Object/Generated/LinkedTrack.pm',
    'Net/Async/Spotify/Object/Generated/Paging.pm',
    'Net/Async/Spotify/Object/Generated/PlayHistory.pm',
    'Net/Async/Spotify/Object/Generated/PlayerError.pm',
    'Net/Async/Spotify/Object/Generated/Playlist.pm',
    'Net/Async/Spotify/Object/Generated/PlaylistTrack.pm',
    'Net/Async/Spotify/Object/Generated/PlaylistTracksRef.pm',
    'Net/Async/Spotify/Object/Generated/PrivateUser.pm',
    'Net/Async/Spotify/Object/Generated/PublicUser.pm',
    'Net/Async/Spotify/Object/Generated/RecommendationSeed.pm',
    'Net/Async/Spotify/Object/Generated/Recommendations.pm',
    'Net/Async/Spotify/Object/Generated/ResumePoint.pm',
    'Net/Async/Spotify/Object/Generated/SavedAlbum.pm',
    'Net/Async/Spotify/Object/Generated/SavedEpisode.pm',
    'Net/Async/Spotify/Object/Generated/SavedShow.pm',
    'Net/Async/Spotify/Object/Generated/SavedTrack.pm',
    'Net/Async/Spotify/Object/Generated/Show.pm',
    'Net/Async/Spotify/Object/Generated/SimplifiedAlbum.pm',
    'Net/Async/Spotify/Object/Generated/SimplifiedArtist.pm',
    'Net/Async/Spotify/Object/Generated/SimplifiedEpisode.pm',
    'Net/Async/Spotify/Object/Generated/SimplifiedPlaylist.pm',
    'Net/Async/Spotify/Object/Generated/SimplifiedShow.pm',
    'Net/Async/Spotify/Object/Generated/SimplifiedTrack.pm',
    'Net/Async/Spotify/Object/Generated/Track.pm',
    'Net/Async/Spotify/Object/Generated/TrackRestriction.pm',
    'Net/Async/Spotify/Object/Generated/TuneableTrack.pm',
    'Net/Async/Spotify/Object/Image.pm',
    'Net/Async/Spotify/Object/LinkedTrack.pm',
    'Net/Async/Spotify/Object/Paging.pm',
    'Net/Async/Spotify/Object/PlayHistory.pm',
    'Net/Async/Spotify/Object/PlayerError.pm',
    'Net/Async/Spotify/Object/Playlist.pm',
    'Net/Async/Spotify/Object/PlaylistTrack.pm',
    'Net/Async/Spotify/Object/PlaylistTracksRef.pm',
    'Net/Async/Spotify/Object/PrivateUser.pm',
    'Net/Async/Spotify/Object/PublicUser.pm',
    'Net/Async/Spotify/Object/RecommendationSeed.pm',
    'Net/Async/Spotify/Object/Recommendations.pm',
    'Net/Async/Spotify/Object/ResumePoint.pm',
    'Net/Async/Spotify/Object/SavedAlbum.pm',
    'Net/Async/Spotify/Object/SavedEpisode.pm',
    'Net/Async/Spotify/Object/SavedShow.pm',
    'Net/Async/Spotify/Object/SavedTrack.pm',
    'Net/Async/Spotify/Object/Show.pm',
    'Net/Async/Spotify/Object/SimplifiedAlbum.pm',
    'Net/Async/Spotify/Object/SimplifiedArtist.pm',
    'Net/Async/Spotify/Object/SimplifiedEpisode.pm',
    'Net/Async/Spotify/Object/SimplifiedPlaylist.pm',
    'Net/Async/Spotify/Object/SimplifiedShow.pm',
    'Net/Async/Spotify/Object/SimplifiedTrack.pm',
    'Net/Async/Spotify/Object/Track.pm',
    'Net/Async/Spotify/Object/TrackRestriction.pm',
    'Net/Async/Spotify/Object/TuneableTrack.pm',
    'Net/Async/Spotify/Scope.pm',
    'Net/Async/Spotify/Token.pm',
    'Net/Async/Spotify/Util.pm'
);

my @scripts = (
    'bin/spotify-cli.pl'
);

# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    close $fh and skip("$file uses -T; not testable with PERL5LIB", 1)
        if grep { $_ eq '-T' } @switches and $ENV{PERL5LIB};

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


