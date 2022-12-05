#!/usr/local/bin/perl

use strict;
use warnings;

use utf8;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

=encoding UTF8

=head1 NAME

C<spotify-cli.pl> - Script to interact with Spotify API in various ways.

=head1 SYNOPSIS

    perl bin/spotify-cli.pl -i

=head1 DESCRIPTION

This script allows you to interact with Spotify API in multiple different ways.
Providing you with a convinent way to query Spotify API by either the set of predefined commands or inline requests.

=cut

=head1 OPTIONS

=over 4

=item B<-c>, B<--client-id>=I<Spotify App Client ID>

Your registered Spotify Application Client ID
Can be set as environment variable I<client_id>

=item B<-s>, B<--client-secret>=I<Spotify APP Client Secret>

Your registered Spotify Application Client Secret
Can be set as environment variable I<client_secret>

=item B<-t>, B<--access-token>=I<Spotify Client Access Token>

Optional, if passed there will be no need to obtain token and requests can be directly called using it.
Can be set as environment variable I<access_token>

=item B<-i>, B<--interactive>

If exists it will run this script in interactive mode, where it will continuously wait for a command to perform.
However manual handling for Authentication process.

=item B<-w>, B<--web-server>

If exists it will make the script run in interactive mode, with an HTTP Webserver running in background listening to port 80 on localhost.
So it can process Spotify C<callback> GET requests automatically. and can be extended to receive commands.
Note: define L<http://localhost/callback> as a B<Redirect URI> in your Spotify App settings.
Also if running in Docker, then run container with I<-p 127.0.0.1:80:80/tcp> option.

=item B<-l> I<debug>, B<--log-level>=I<info>

Log level used. with default being I<Info>.

=back

=cut

use Pod::Usage;
use Getopt::Long;
use IO::Async::Loop;
use IO::Async::Stream;
use Future::AsyncAwait;
use Syntax::Keyword::Try;
use Log::Any qw($log);
use Net::Async::Spotify;
use Net::Async::Spotify::Util qw(hash_to_string);
use JSON::MaybeUTF8 qw(:v1);
use Net::Async::HTTP::Server;
use Future::Utils qw(fmap_concat);
use Unicode::UTF8 qw(encode_utf8);
use Scalar::Util qw(blessed);
use Encode qw(encode);

GetOptions(
    'c|client-id=s'     => \(my $client_id = $ENV{client_id}),
    's|client-secret=s' => \(my $client_secret = $ENV{client_secret}),
    't|access-token=s'  => \(my $access_token = $ENV{access_token}),
    'i|interactive'     => \my $interactive,
    'w|web-server'      => \my $webserver,
    'l|log-level=s'     => \(my $log_level = 'info'),
    'h|help'            => \my $help,
);

require Log::Any::Adapter;
Log::Any::Adapter->set( qw(Stdout), log_level => $log_level );

pod2usage(
    {
        -verbose  => 99,
        -sections => "NAME|SYNOPSIS|DESCRIPTION|OPTIONS|COMMANDS",
    }
) if $help;

die 'Need Spotify Client ID and Client Secret' unless ( $client_id and $client_secret );

my $loop = IO::Async::Loop->new;
$loop->add( my $spotify = Net::Async::Spotify->new(
        client_id => $client_id,
        client_secret => $client_secret,
        access_token  => $access_token,
    )
);

my $stream = IO::Async::Stream->new(
    read_handle  => \*STDIN,
    write_handle => \*STDOUT,
    on_read => sub {
        my ( $self, $buffref, $eof ) = @_;

        while( $$buffref =~ s/^(.*\n)// ) {
            my $line = $1;
            my @cmd_array = split ' ', $line;
            my $command = $cmd_array[0];
            unless (defined $command) {
                print "\n";
                pod2usage(
                    {
                        -verbose  => 99,
                        -sections => "COMMANDS",
                        -exitval  => 'NOEXIT',
                    }
                );
                print "Waiting for your Command!...\nCMD: ";
                return 0;
            }

            if (exists &{$command}) {
                # for a happy strict pragma
                my $method = \&{$command};
                $method->(@cmd_array)->retain;
            } else {
                generic->(@cmd_array)->retain;
            }

      }
      return 0;
   }
);
$loop->add( $stream );

my $callback_f = $loop->new_future(label => 'CallbackFuture');
# Web server for incoming callback request
my $server = Net::Async::HTTP::Server->new(
    on_request => sub {
        my ( $self, $req ) = @_;
        $log->tracef('Webserver receives %s %s: %s | %s', $req->method, $req->path, {$req->query_form}, $req->body);
        if ( $req->method eq 'GET' and $req->path eq '/callback' ) {
            # That's what we are waiting for.
            my %params = $req->query_form;
            $callback_f->done(%params) unless $callback_f->is_done;

            my $response = HTTP::Response->new(200);
            $response->add_content(encode_json_utf8({response => 'Got it! From spotify-cli.pl ;)'}));
            $response->content_type("application/json");
            $response->content_length(length $response->content);

            $req->respond($response);
        }
    },
);
$loop->add( $server );

my $listner = await $server->listen(
    addr => {
        family   => 'inet',
        socktype => 'stream',
        port     => 80,
    },
) if $webserver;

my %authorize = $spotify->authorize(scope => ['scopes'], show_dialog => 'false');

$stream->write(sprintf("Your Authorize URI is (state: %s) :\n\n%s\n\n", $authorize{state}, $authorize{uri}));

if ( $interactive ) {
    $stream->write("Please insert your `code` response in callback URL...\n");
    my ( $auth_code ) = await $stream->read_until( "\n" );
    chomp $auth_code;

    $stream->write("Please insert your `state` response in callback URL...\n");
    my ( $auth_state ) = await $stream->read_until( "\n" );
    chomp $auth_state;

    await $spotify->obtain_token(code => $auth_code, auto_refresh => 1);
    $stream->write("Waiting for your Command!...\nCMD: ");
    $loop->run;
} elsif ( $webserver ) {
    my %auth_res = await $callback_f;
    if ( $auth_res{state} eq $authorize{state} ) {
        await $spotify->obtain_token(code => $auth_res{code}, auto_refresh => 1);
        $stream->write("Waiting for your Command!...\nCMD: ");
        $loop->run;
    }
}

sub write_to_stream {
    my $content = shift;
    my $to_write = '';
    try {
        # since we are Getting Net::Async::Spotify::Object here.
        # need to implement to_hash there in order to be able to do this
        #$to_write = encode_json_utf8($content);
        if ( ref $content eq 'HASH' ) {
            if ( exists $content->{content} and blessed $content->{content} and $content->{content}->can('to_hash') ) {
                $to_write = $content->{content}->to_human;
            } else {
                $to_write = hash_to_string( $content ) . "\n";
            }
        } else {
            $to_write = $content if defined $content;
            $to_write .= "\n";
        }
    } catch ($e) {
        $stream->write("Could not parse response. Error: $e\n");
    }
    $stream->write(encode_utf8($to_write)."\nWaiting for your Command!...\nCMD: ");
}

=head1 COMMANDS

Available Commands:

=head2 CMD => p I<uri(optional)> I<device_id(optional)>

Play - Player -> start_a_users_playback

=cut

async sub p {
    my @cmd_array = @_;
    my $uri = $cmd_array[1];
    my $device_id = $cmd_array[2] || $spotify->api->player->{selected_device}->id;
    my $r = await $spotify->api->player->start_a_users_playback(
        $uri ? (uris => $uri) : (),
        $device_id ? (device_id => $device_id)  : ()
    );
    write_to_stream($r);
}

=head2 CMD => pu

Pause - Player -> pause_a_users_playback

=cut

async sub pu {
    my $r = await $spotify->api->player->pause_a_users_playback();
    write_to_stream($r);
}

=head2 CMD => n

Next - Player -> skip_users_playback_to_next_track

=cut

async sub n {
    await $spotify->api->player->skip_users_playback_to_next_track();
    my $r = await $spotify->api->player->get_information_about_the_users_current_playback();
    write_to_stream($r->{content}->to_human);
}

=head2 CMD => b

Previous - Player -> skip_users_playback_to_previous_track

=cut

async sub b {
    my $r = await $spotify->api->player->skip_users_playback_to_previous_track();
    write_to_stream($r);
}

=head2 CMD => ff I<seconds>

FastForward the current playing track with the passed.

=cut

async sub ff {
    my @cmd_array = @_;

    my $seconds = 1000 * $cmd_array[1];
    my $current =  await $spotify->api->player->get_information_about_the_users_current_playback();
    my $r = await $spotify->api->player->seek_to_position_in_currently_playing_track(
        position_ms => $seconds + $current->{content}->progress_ms
    );
    write_to_stream($r);
}

=head2 CMD => set_s I<second>

Set the current playing track position to the passed second.

=cut

async sub set_s {
    my @cmd_array = @_;

    my $seconds = 1000 * $cmd_array[1];
    my $r = await $spotify->api->player->seek_to_position_in_currently_playing_track(position_ms => $seconds);
    write_to_stream($r);
}

=head2 CMD => sh I<(true)|false>

Toggle Shuffle for current Playback context.

=cut

async sub sh {
    my @cmd_array = @_;

    my $state = $cmd_array[1] || 'true';
    my $r = await $spotify->api->player->toggle_shuffle_for_users_playback(state => $state);
    write_to_stream($r);
}

=head2 CMD => c

Current Track - Player -> get_information_about_the_users_current_playback

=cut

async sub c {
    my $r;
    try {
        $r = await $spotify->api->player->get_information_about_the_users_current_playback();
        write_to_stream($r->{content}->to_human);
    } catch ($e) {
        warn "ERROR " . hash_to_string($e);
    }
}

=head2 CMD => d

Available Devices - Player -> get_a_users_available_devices

=cut

async sub d {
    my $r = await $spotify->api->player->get_a_users_available_devices();
    write_to_stream($r->{content}->to_human);
}

=head2 CMD => d_select I<name|ID> I<1|(0)/play>

Selects a device, That will be used for Player API during this session.

=cut

async sub d_select {
    my @cmd_array = @_;
    try {
        my $dvcs = await $spotify->api->player->get_a_users_available_devices();
        my @sel_d = grep { $_->name eq $cmd_array[1] or $_->id eq $cmd_array[1] } $dvcs->{content}->devices->@*;
        $spotify->api->player->{selected_device} = $sel_d[0];
        await $spotify->api->player->start_a_users_playback(device_id => $sel_d[0]->id) if $cmd_array[2];
    } catch ($e) {
        $log->warnf('error : %s', $e);
    }
    write_to_stream('OK');
}

=head2 CMD => t I<device_id>

Transfer playback to device and start playing.

=cut

async sub t {
    my @cmd_array = @_;
    my $device_id = $cmd_array[1] || $spotify->api->player->{selected_device}->id;
    my $r = await $spotify->api->player->transfer_a_users_playback(device_ids => $device_id, play => 'true');
    write_to_stream($r);
}

=head2 CMD => v I<volume_percent>

Sets the current active device's volume.

=cut

async sub v {
    my @cmd_array = @_;
    my $devices = await $spotify->api->player->get_a_users_available_devices();
    my $device_id;
    for my $device ($devices->{content}{devices}->@*) {
        if($device->{is_active}) {
            $device_id = $device->{id};
            last;
        }
    }
    my $r = await $spotify->api->player->set_volume_for_users_playback(volume_percent => $cmd_array[1], device_id => $device_id);
    write_to_stream($r);
}

=head2 CMD => l

Like the current playing song.

=cut

async sub l {
    my @cmd_array = @_;
    my $current = await $spotify->api->player->get_information_about_the_users_current_playback();
    my $id = $current->{content}->item->id;
    if ( $id ) {
        my $r = await $spotify->api->library->save_tracks_user(ids => $id);
        write_to_stream($r);
    } else {
        write_to_stream('Could not get Track ID');
    }

}

=head2 CMD => ul

Remove the current playing song from Liked.

=cut

async sub ul {
    my @cmd_array = @_;
    my $current = await $spotify->api->player->get_information_about_the_users_current_playback();
    my $id = $current->{content}->item->id;
    if ( $id ) {
        my $r = await $spotify->api->library->remove_tracks_user(ids => $id);
        write_to_stream($r);
    } else {
        write_to_stream('Could not get Track ID');
    }

}

=head2 CMD => f

Current track Audio Features.

=cut

async sub f {
    my @cmd_array = @_;
    my $current = await $spotify->api->player->get_information_about_the_users_current_playback();
    my $id = $current->{content}->item->id;
    if ( $id ) {
        my $r = await $spotify->api->tracks->get_audio_features(id => $id);
        write_to_stream($r->{content}->to_human);
    } else {
        write_to_stream('Could not get Track ID');
    }
}

=head2 CMD => fc_dance I<dance_level(0.6)>

Find in Current Contenxt Track with more than the passed danceablitiy leve.

=cut

async sub fc_dance {
    my @cmd_array = @_;

    my $current_features = async sub {

        my $current = await $spotify->api->player->get_information_about_the_users_current_playback();
        my $id = $current->{content}->item->id;
        if ( $id ) {
            my $r = await $spotify->api->tracks->get_audio_features(id => $id);
            return $r;
        } else {
            return {error => 'Could not get Track ID'};
        }
    };

    my $f = await $current_features->();
    my $c = 0;
    my $danceability = $cmd_array[1] || 0.6;
    while ( $f->{content}->danceability < $danceability ) {
        $log->warnf('%d | Still less %s Next!', $c, $f->{content}->danceability);
        await $spotify->api->player->skip_users_playback_to_next_track();
        $f = await $current_features->();
    }
    $f->{count} = $c;
    write_to_stream($f);
}

=head2 CMD => g

Get a list of available recommendation genres

=cut

async sub g {
    my @cmd_array = @_;

    my $r = await $spotify->api->browse->get_recommendation_genres();
    write_to_stream($r);

}

=head2 CMD => i I<(tracks)|artists> I<s|(m)|l> I<count(2)> I<offset(0)>

Get your top tracks | artists. where time_range => s:short_term, m:medium_term, l:long_term

=cut

async sub i {
    my @cmd_array = @_;

    my $type = $cmd_array[1] || 'tracks';
    my $time_range = $cmd_array[2] || 's';
    my $limit = $cmd_array[3] || 2;
    my $level = $cmd_array[4] || 0;
    my $range = 'medium_term';
    if ( $time_range eq 's' ) {
        $range = 'short_term';
    } elsif ( $time_range eq 'l' ) {
        $range = 'long_term';
    }

    try {
        my $r = await $spotify->api->personalization->get_users_top_artists_and_tracks(
            type       => $type,
            time_range => $range,
            limit      => $limit,
            offset     => $level
        );
        my $output;
        $output .= $_->to_human ."\n" for $r->{content}->items->@*;
        write_to_stream($output);
    } catch ($e) {
        $log->warnf('ddd %s', hash_to_string($e))
    }
}

=head2 CMD => seed_t I<ID|(current)>

add the track as a seed track (will keep latest selected 2 only)

=cut

async sub seed_t {
    my @cmd_array = @_;
    my $id = $cmd_array[1];
    unless ( defined $id ) {
        my $current = await $spotify->api->player->get_information_about_the_users_current_playback();
        $id = $current->{content}->item->id;
        return {error => 'Could not get Track ID'} unless defined $id;
    }
    unshift $spotify->api->personalization->{seed_tracks}->@*, $id;
    pop $spotify->api->personalization->{seed_tracks}->@* if scalar($spotify->api->personalization->{seed_tracks}->@*) > 2;
    write_to_stream('OK '.hash_to_string($spotify->api->personalization->{seed_tracks}));
}

=head2 CMD => seed_a I<ID|(current)>

add the artist as a seed track (will keep latest selected 2 only)

=cut

async sub seed_a {
    my @cmd_array = @_;
    my $id = $cmd_array[1];
    unless ( defined $id ) {
        my $current = await $spotify->api->player->get_information_about_the_users_current_playback();
        $id = $current->{content}->item->artists->[0]->id;
        return {error => 'Could not get Track ID'} unless defined $id;
    }
    unshift $spotify->api->personalization->{seed_artists}->@*, $id;
    pop $spotify->api->personalization->{seed_artists}->@* if scalar($spotify->api->personalization->{seed_artists}->@*) > 2;
    write_to_stream('OK'.hash_to_string($spotify->api->personalization->{seed_artists}));
}

=head2 CMD => rng I<genre(reggae)> I<(auto)|manual> I<acousticness> I<danceability> I<energy> I<instrumentalness> I<liveness> I<loudness> I<speechiness> I<tempo> I<valence>

Get you a random track based on passed Genre, Tracks and Artists used as seed, Auto for them to be your top tracks and artists.
and manual for selected seeded ones. Also accepts constrains on track features.

=cut

async sub rng {
    my @cmd_array = @_;

    my $genre =  $cmd_array[1] || 'reggae';
    my $seed_source = $cmd_array[2] || 'auto';
    my ($tracks_ids, $artists_ids);
    if ( $seed_source eq 'auto' ) {
        my $top_tracks = await $spotify->api->personalization->get_users_top_artists_and_tracks(type => 'tracks', limit => 2, time_range => 'short_term');
        $tracks_ids = [ map { $_->id } $top_tracks->{content}->items->@*];
        my $top_artists = await $spotify->api->personalization->get_users_top_artists_and_tracks(type => 'artists', limit => 2, time_range => 'short_term');
        $artists_ids = [ map { $_->id } $top_artists->{content}->items->@*];
    }
    $tracks_ids = $spotify->api->personalization->{seed_tracks} unless defined $tracks_ids;
    $artists_ids = $spotify->api->personalization->{seed_artists} unless defined $artists_ids;
    my %rec_args = (
        seed_tracks => $tracks_ids || [],
        seed_artists => $artists_ids || [],
        seed_genres => [$genre],
        limit => 100,
    );
    my %h;
    @h{qw(acousticness danceability energy instrumentalness liveness loudness speechiness tempo valence)} = @cmd_array[3 .. 12];
    for my $k (keys %h) {
        # zero value is skipped.
        if (defined $h{$k} and $h{$k}) {
            $rec_args{"target_$k"} = $h{$k};
            $rec_args{"max_$k"} = $h{$k} + 0.1;
            $rec_args{"min_$k"} = $h{$k} - 0.1;
        }
    }
    my $rng_rec = await $spotify->api->browse->get_recommendations(%rec_args);
    my $suggested_ids = join ',', map { $_->id } $rng_rec->{content}->tracks->@*;
    my $suggested_uris = join ',', map { $_->uri } $rng_rec->{content}->tracks->@*;

    # Spotify API seems to be good enough with the accuracy. so do not re-check.
    # my $playlist_id =  $spotify->api->playlists->{selected_playlist}->id;
    # await $spotify->api->playlists->add_tracks_to_playlist(playlist_id => $playlist_id, uris => $suggested_uris);
    # my $t_af = await $spotify->api->tracks->get_several_audio_features(ids => $suggested_ids);

    await $spotify->api->player->start_a_users_playback(uris => $suggested_uris);

    my $r = await $spotify->api->player->get_information_about_the_users_current_playback();
    write_to_stream("Tracks found and currently in queue: " . scalar @$suggested_ids . " Tracks (max. 100)");
    write_to_stream($r->{content}->to_human);
}

=head2 CMD => me

Current user Info.

=cut

async sub me {
    my @cmd_array = @_;
    my $me = await $spotify->api->users->get_current_users_profile();
    write_to_stream($me);
}

=head2 CMD => s I<string>

Search for a track

=cut

async sub s {
    my @cmd_array = @_;
    shift @cmd_array;

    try {
        my $r = await $spotify->api->search->search(type => 'track', q => join(' ', @cmd_array));
        $log->warnf('dddddd %s', hash_to_string($r));
    } catch ($e) {
        warn hash_to_string($e);
    }
}

# Playlists
=head2 CMD => pl_ls

List user's playlists.

=cut

async sub pl_ls {
    my @cmd_array = @_;
    try {
        my $pls = await $spotify->api->playlists->get_a_list_of_current_users_playlists(limit => 50);
        my %r = map { $_->name  => { id => $_->id, description => $_->description } } $pls->{content}->items->@*;
        write_to_stream(hash_to_string(\%r));
    } catch ($e) {
        warn hash_to_string($e);
    }
}

=head2 CMD => pl_add I<playlist_name> I<public:(true)|false> I<"Description">

Creates a new playlist for user.

=cut

async sub pl_add {
    my @cmd_array = @_;
    my $user_id = $cmd_array[4];
    unless ( defined $user_id ) {
        my $me = await $spotify->api->users->get_current_users_profile();
        $user_id = $me->{content}->id;
    }
    my $r = await $spotify->api->playlists->create_playlist(
        user_id => $user_id,
        name => $cmd_array[1] || 'NoName',
        public => $cmd_array[2] || 'true',
        $cmd_array[3] ? (description => $cmd_array[3]) : ()
    );
    write_to_stream($r);
}

=head2 CMD => pl_select I<1|0(playit?)> I<name|ID>

Selects a playlist, passing a second parameter will play it too.

=cut

async sub pl_select {
    my @cmd_array = @_;
    shift @cmd_array;
    my $play_it = shift @cmd_array;
    my $name = join ' ', @cmd_array;
    my $pl;
    try {
        my $pls = await $spotify->api->playlists->get_a_list_of_current_users_playlists(limit => 50);
        my @sel_pl = grep { encode('UTF-8', $_->name) =~ m/$name/ or $_->id eq $name } $pls->{content}->items->@*;
        $log->warnf('NAME: %s | %s', $name, \@sel_pl);
        $pl = $spotify->api->playlists->{selected_playlist} = $sel_pl[0];
        await $spotify->api->player->start_a_users_playback(context_uri => $sel_pl[0]->uri) if $play_it;
    } catch ($e) {
        $log->warnf('error : %s', $e);
    }
    write_to_stream('OK : ' . $pl->name);
}

=head2 CMD => atp I<playlistID(default selected)>

Adds the current playing track to a playlist.
If no PlaylistID passed it will use selected.

=cut

async sub atp {
    my @cmd_array = @_;

    try {
        my $playlist_id = $cmd_array[1] || $spotify->api->playlists->{selected_playlist}->id;
        my $c = await $spotify->api->player->get_information_about_the_users_current_playback();
        my $d = $c->{content}->item->uri;

        await $spotify->api->playlists->add_tracks_to_playlist(playlist_id => $playlist_id, uris => $d);
    } catch ($e) {
        $log->warnf('error %s', $e);
    }
    write_to_stream('OK');
}

=head2 CMD => rfp I<playlistID(default selected)>

Removes the current playing track from a playlist.
If no PlaylistID passed it will use selected.

=cut

async sub rfp {
    my @cmd_array = @_;

    try {
        my $playlist_id = $cmd_array[1] || $spotify->api->playlists->{selected_playlist}->id;
        my $c = await $spotify->api->player->get_information_about_the_users_current_playback();
        my $d = $c->{content}->item->uri;

        await $spotify->api->playlists->remove_tracks_playlist(playlist_id => $playlist_id, tracks => [{ uri => $d}] );
    } catch ($e) {
        $log->warnf('error %s', $e);
    }
    write_to_stream('OK');
}

=head2 CMD => I<api_name> I<method_name> I<%args>

Generic - Where it will take first argument as API name, second would be the method name. And whaterve comes after that would be
a key value arguments.

=cut

async sub generic {
    my @cmd_array = @_;
    my $r;
    try{
        my $api_name = $cmd_array[0];
        my $api_cmd = $cmd_array[1];
        $r = await $spotify->api->$api_name->$api_cmd(splice @cmd_array, 2);
    } catch ($e) {
        $r = {fail => $e};
    }
    write_to_stream($r);
}
