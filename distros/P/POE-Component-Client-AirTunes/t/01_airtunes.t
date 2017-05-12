use strict;
use Test::More;

plan $ENV{AIRTUNES_TEST} ? 'no_plan' : (skip_all => 'No AIRTUNES_TEST');

my $ip  = "192.168.1.100";
my $mp3 = "$ENV{HOME}/mp3/gday.m4a";

use POE qw( Component::Client::AirTunes );

POE::Session->create(
    inline_states => {
        _start       => \&_start,
        error        => \&error,
        connected    => \&connected,
        pause_song   => \&pause_song,
        resume_song  => \&resume_song,
        stop_song    => \&stop_song,
    },
    heap => {
        ip  => $ip,
        mp3 => $mp3,
    },
);

$poe_kernel->run();

sub _start {
    $_[KERNEL]->alias_set('main');
    $_[HEAP]->{airtunes} = POE::Component::Client::AirTunes->new(
        host   => $_[HEAP]->{ip},
        alias  => "airtunes",
        parent => 'main',
        events => {
            connected     => 'connected',
            error         => 'error',
            done          => 'done',
        },
        debug => 1,
    );
}

sub error {
    die "Error: $_[ARG0]\n";
}

sub connected {
    my $audio_jack = $_[HEAP]->{airtunes}->audio_jack;
    warn "connected to $_[HEAP]->{ip}\n";
    warn "  Audio-Jack-Status: $audio_jack->{status}\n";
    warn "  Audio-Jack-Type:   $audio_jack->{type}\n";
    $_[KERNEL]->post(airtunes => volume => 100);
    $_[KERNEL]->post(airtunes => play => $_[HEAP]->{mp3});
    $_[KERNEL]->delay('pause_song', 10);
}

sub pause_song {
    $_[KERNEL]->post(airtunes => pause => ());
    $_[KERNEL]->delay('resume_song', 10);
}

sub resume_song {
    $_[KERNEL]->post(airtunes => play => ());
    $_[KERNEL]->delay('stop_song', 10);
}

sub stop_song {
    $_[KERNEL]->post(airtunes => stop => ());
}
