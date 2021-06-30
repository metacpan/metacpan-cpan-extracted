#!/usr/local/bin/perl

use strict;
use warnings;

use utf8;

our $VERSION = '0.001'; # VERSION
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
use Data::Dumper;
use JSON::MaybeUTF8 qw(:v1);
use Net::Async::HTTP::Server;

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
        $to_write = Dumper($content);
    } catch ($e) {
        $stream->write("Could not parse response. Error: $e\n");
    }
    $stream->write($to_write."\nWaiting for your Command!...\nCMD: ");
}

=head1 COMMANDS

Available Commands:

=head2 CMD => p

Play - Player -> start_a_users_playback

=cut

async sub p {
    my $r = await $spotify->api->player->start_a_users_playback();
    write_to_stream($r);
}

=head2 CMD => pu

Pause - Player -> pause_a_users_playback

=cut

async sub pu {
    $stream->write("Pausing Player...\n");
    my $r = await $spotify->api->player->pause_a_users_playback();
    write_to_stream($r);
}

=head2 CMD => n

Next - Player -> skip_users_playback_to_next_track

=cut

async sub n {
    $stream->write("NEXT! :D\n");
    my $r = await $spotify->api->player->skip_users_playback_to_next_track();
    write_to_stream($r);
}

=head2 CMD => b

Previous - Player -> skip_users_playback_to_previous_track

=cut

async sub b {
    my $r = await $spotify->api->player->skip_users_playback_to_previous_track();
    write_to_stream($r);
}

=head2 CMD => c

Current Track - Player -> get_information_about_the_users_current_playback

=cut

async sub c {
    my $r = await $spotify->api->player->get_information_about_the_users_current_playback();
    write_to_stream($r);
}

=head2 CMD => d

Available Devices - Player -> get_a_users_available_devices

=cut

async sub d {
    my $r = await $spotify->api->player->get_a_users_available_devices();
    write_to_stream($r);
}

=head2 CMD => t I<device_id>

Transfer playback to device and start playing.

=cut

async sub t {
    my @cmd_array = @_;
    my $r = await $spotify->api->player->transfer_a_users_playback(device_ids => $cmd_array[1], play => 'true');
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
    my $id = $current->{content}->data->{item}{id};
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
    my $id = $current->{content}->data->{item}{id};
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
    my $id = $current->{content}->data->{item}{id};
    if ( $id ) {
        my $r = await $spotify->api->tracks->get_audio_features(id => $id);
        write_to_stream($r);
    } else {
        write_to_stream('Could not get Track ID');
    }
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
